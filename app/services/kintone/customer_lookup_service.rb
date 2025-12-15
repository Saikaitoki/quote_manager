# app/services/kintone/customer_lookup_service.rb
module Kintone
  class CustomerLookupService
    APP_ID    = Rails.configuration.x.kintone.customer_app_id
    API_TOKEN = Rails.configuration.x.kintone.customer_token

    # 得意先マスタ側のフィールドコード
    CUSTOMER_CODE_FIELD = "得意先コード"
    CUSTOMER_NAME_FIELD = "得意先名"

    def initialize(code)
      @code = code.to_s.strip
    end

    def call
      return nil if @code.blank?

      client = Client.new(api_token: API_TOKEN)

      params = {
        app:   APP_ID,
        query: %(#{CUSTOMER_CODE_FIELD} = "#{@code}")
      }

      # ★ ここを POST → GET に変更
      res = client.get("/k/v1/records.json", params)

      records = res["records"] || []
      return nil if records.empty?

      rec = records.first

      {
        code: rec.dig(CUSTOMER_CODE_FIELD, "value"),
        name: rec.dig(CUSTOMER_NAME_FIELD, "value"),
        rates: {
          proper:     rec.dig("プロパー掛率", "value"),
          kurashino:  rec.dig("クラシノウツワ掛率", "value"),
          common:     rec.dig("common掛率", "value"),
          essence:    rec.dig("essence掛率", "value"),
          porcelains: rec.dig("The_Porcelains掛率", "value"), # フィールドコード要確認: 空白アンダースコア変換など
          f_symbol:   rec.dig("F記号掛率", "value"),
          h_symbol:   rec.dig("H記号掛率", "value")
        }
      }
    end
  end
end
