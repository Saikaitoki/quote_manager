# app/services/kintone/quote_sync_service.rb
module Kintone
  class QuoteSyncService
    CREATE_PATH = "/k/v1/record.json"
    UPDATE_PATH = "/k/v1/record.json"
    MAX_RETRIES = 2

    def initialize(quote, client: Client.new)
      @quote  = quote
      @client = client
    end

    # これを呼べば create or update を自動判別して同期
    def sync!
      mapper = QuoteMapper.new(@quote)

      if @quote.kintone_record_id.present?
        update!(mapper)
      else
        create!(mapper)
      end
    end

    private

    def create!(mapper)
      body = mapper.to_create_payload
      data = with_retries { @client.post(CREATE_PATH, body) }

      record_id = data["id"] || data.dig("record", "$id", "value")
      revision  = data["revision"]&.to_i

      @quote.update_columns(
        kintone_record_id: record_id.to_s,
        kintone_revision:  revision
      )

      true
    end

    def update!(mapper)
      body = mapper.to_update_payload(
        record_id: @quote.kintone_record_id,
        revision:  @quote.kintone_revision
      )

      data = with_retries { @client.put(UPDATE_PATH, body) }
      revision = data["revision"]&.to_i

      @quote.update_columns(kintone_revision: revision)
      true
    rescue KintoneError => e
      # revision 衝突（他ユーザーがkintone側で編集したなど）の場合の扱い
      raise unless e.code == "GAIA_RECMODIFIED"

      # 方針: revision指定なしで上書き更新（運用次第でここを変えてもよい）
      body = mapper.to_update_payload(
        record_id: @quote.kintone_record_id,
        revision:  nil
      )
      data = with_retries { @client.put(UPDATE_PATH, body) }
      @quote.update_columns(kintone_revision: data["revision"]&.to_i)
      true
    end

    def with_retries
      attempts = 0
      begin
        attempts += 1
        yield
      rescue KintoneError => e
        if e.status.to_i == 429 && attempts <= MAX_RETRIES
          sleep(1.0 * attempts)
          retry
        end
        raise
      end
    end
  end
end
