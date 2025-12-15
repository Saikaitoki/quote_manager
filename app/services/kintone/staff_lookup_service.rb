# app/services/kintone/staff_lookup_service.rb
module Kintone
  class StaffLookupService
    APP_ID    = Rails.configuration.x.kintone.staff_app_id
    API_TOKEN = Rails.configuration.x.kintone.staff_token

    # 営業担当者マスタ側のフィールドコード
    STAFF_CODE_FIELD = "営業担当者コード"
    STAFF_NAME_FIELD = "営業担当者"

    def initialize(code)
      @code = code.to_s.strip
    end

    def call
      return nil if @code.blank?

      client = Client.new(api_token: API_TOKEN)

      params = {
        app:   APP_ID,
        query: %(#{STAFF_CODE_FIELD} = "#{@code}")
      }

      # ★ ここも GET を使う
      res = client.get("/k/v1/records.json", params)

      records = res["records"] || []
      return nil if records.empty?

      rec = records.first

      {
        code: rec.dig(STAFF_CODE_FIELD, "value"),
        name: rec.dig(STAFF_NAME_FIELD, "value")
      }
    end
  end
end
