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

    def delete!
      Rails.logger.info("[kintone-delete] Start delete! for id=#{@quote.id}, kintone_id=#{@quote.kintone_record_id}")
      return if @quote.kintone_record_id.blank?

      payload = {
        app: QuoteMapper::APP_ID,
        ids: [ @quote.kintone_record_id.to_i ]
      }

      Rails.logger.info("[kintone-delete] Sending delete payload: #{payload.inspect}")
      with_retries { @client.delete("/k/v1/records.json", payload) }
      Rails.logger.info("[kintone-delete] Success")
      true
    rescue KintoneError => e
      # 既に消えている(404)なら正常とみなす
      # GAIA_RE01: The specified record (id: ...) is not found.
      return true if e.message.include?("not found") || e.code == "GAIA_RE01"

      Rails.logger.error("[kintone-delete] Quote##{@quote.id} delete failed: #{e.message}")
      raise
    end

    private

    def create!(mapper)
      body = mapper.to_create_payload
      data = with_retries { @client.post(CREATE_PATH, body) }

      record_id = data["id"] || data.dig("record", "$id", "value")
      revision  = data["revision"]&.to_i

      # 同期した内容を raw_payload として保存
      # body[:record] は Hash なので、textカラムに入れるために明示的に JSON 化する
      @quote.update_columns(
        kintone_record_id: record_id.to_s,
        kintone_revision:  revision,
        raw_payload:       body[:record].to_json
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

      @quote.update_columns(
        kintone_revision: revision,
        raw_payload:      body[:record].to_json
      )
      true
    rescue KintoneError => e
      # revision 衝突 (GAIA_RECMODIFIED or GAIA_CO02)
      raise unless %w[GAIA_RECMODIFIED GAIA_CO02].include?(e.code)

      # 強制更新
      body = mapper.to_update_payload(
        record_id: @quote.kintone_record_id,
        revision:  nil
      )
      data = with_retries { @client.put(UPDATE_PATH, body) }

      @quote.update_columns(
        kintone_revision: data["revision"]&.to_i,
        raw_payload:      body[:record].to_json
      )
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
