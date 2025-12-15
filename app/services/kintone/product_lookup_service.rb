# app/services/kintone/product_lookup_service.rb
module Kintone
  class ProductLookupService
    def initialize(product_code)
      @product_code = product_code.to_s.strip
    end

    def call
      return nil if @product_code.blank?

      client = build_client
      app_id = ENV["KINTONE_PRODUCT_APP_ID"].to_s

      if app_id.blank?
        Rails.logger.error("[ProductLookup] KINTONE_PRODUCT_APP_ID is blank")
        return nil
      end

      record = find_record(client, app_id)
      return nil unless record

      build_response(record)
    rescue Kintone::KintoneError => e
      Rails.logger.error("[ProductLookup] KintoneError #{e.code} #{e.status} #{e.message}")
      Rails.logger.error(e.details.inspect) if e.details
      nil
    rescue => e
      Rails.logger.error("[ProductLookup] #{e.class}: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      nil
    end

    private

    # ==== ここが client.rb に合わせたポイント ====
    def build_client
      # 商品マスタ用トークンがあればそれを優先、なければ既存の KINTONE_API_TOKEN を使う
      token =
        ENV["KINTONE_PRODUCT_API_TOKEN"].presence ||
        ENV["KINTONE_API_TOKEN"]

      Kintone::Client.new(api_token: token)
      # domain / timeout は Rails.configuration.x.kintone.* のデフォルトをそのまま利用
    end

    # 商品CDで1件検索（数値/文字列どちらにも対応）
    def find_record(client, app_id)
      queries = []

      if @product_code.match?(/\A\d+\z/)
        # 商品CD が数値フィールドの可能性が高いので、数値→文字列の順で試す
        queries << %(商品CD = #{@product_code})
        queries << %(商品CD = "#{@product_code}")
      else
        queries << %(商品CD = "#{@product_code}")
      end

      queries.each do |q|
        Rails.logger.info("[ProductLookup] app=#{app_id} query=#{q}")

        res = client.get(
          "/k/v1/records.json",
          {
            app: app_id,
            query: q,
            totalCount: false
          }
        )

        records = res["records"] || []
        return records.first if records.any?
      end

      nil
    end

    def build_response(r)
      {
        code:          r.dig("商品CD", "value"),
        name:          r.dig("商品名", "value"),
        stock:         r.dig("差引実", "value"),
        reserved_qty:    r.dig("仮押数量", "value"), 
        available_stock: r.dig("在庫数",   "value"), # ★ （差引実 - 仮押数量）
        price:         r.dig("上代", "value"),
        special_price: r.dig("特別上代", "value"),
        inner_qty:     r.dig("内箱入数", "value"),
        catalog_no:    r.dig("記号", "value"),
        page:          r.dig("頁CD", "value"),
        row:           r.dig("行CD", "value"),
        package:       r.dig("荷姿", "value")
      }
    end
  end
end
