# app/services/kintone/product_reservation_service.rb

module Kintone
  class ProductReservationService
    PRODUCT_APP_ID     = Rails.configuration.x.kintone.product_app_id
    PRODUCT_CODE_FIELD = "商品CD"   # 商品マスタ側のフィールドコード
    RESERVED_QTY_FIELD = "仮押数量" # 仮押数量のフィールドコード

    def initialize(quote, client: Client.new(
      domain:    Rails.configuration.x.kintone.domain,
      api_token: Rails.configuration.x.kintone.product_token, # 商品マスタ用トークン
      timeout:   Rails.configuration.x.kintone.timeout
    ))
      @quote  = quote
      @client = client
    end

    # ==========================
    # 1. 旧仕様: 「見積の全明細分をそのまま仮押数量に加算する」
    #    - create 時だけ使う想定。
    #    - 差分更新導入後は、必要なければ削除・未使用化してもよい。
    # ==========================
    def reserve!
      @quote.items.each do |item|
        qty = item.quantity.to_i
        next if qty <= 0 || item.product_code.blank?

        increment_reserved_quantity(item.product_code, qty)
      end
    end

    # ==========================
    # 2. 新仕様: 差分更新
    #    - old_items / new_items は { "商品CD" => 数量 } を想定。
    #    - Quote 側から呼び出すことを前提。
    # ==========================
    def update_reservation!(old_items:, new_items:)
      deltas = build_deltas(old_items, new_items)

      # ★ デバッグログ: 計算された差分一覧
      Rails.logger.info("[reserve-debug] deltas=#{deltas}")

      deltas.each do |product_code, delta|
        next if delta.zero?

        Rails.logger.info("[reserve-debug] apply delta product_code=#{product_code} delta=#{delta}")
        update_reserved_quantity(product_code, delta)
      end
    end


    private

    # ==========================
    # 共通: 差分計算
    # ==========================
    def build_deltas(old_items, new_items)
      keys = (old_items.keys + new_items.keys).uniq
      keys.index_with do |code|
        new_items[code].to_i - old_items[code].to_i
      end
    end

      # ==========================
      # reserve! 用: 「qty 分だけ単純加算」
      # ==========================
      def increment_reserved_quantity(product_code, qty)
      record = find_product_record(product_code)
      return unless record

      id      = record.dig("$id", "value")
      current = record.dig(RESERVED_QTY_FIELD, "value").to_i
      new_val = current + qty

      body = {
        app: PRODUCT_APP_ID,
        records: [
          {
            id: id,
            record: {
              RESERVED_QTY_FIELD => { value: new_val.to_s }
            }
          }
        ]
      }

      Rails.logger.info("[reserve-debug] increment body=#{body}")

      @client.put("/k/v1/records.json", body)
    end


    # ==========================
    # 差分更新用: delta 分だけ増減（正の値・負の値両方）
    # ==========================
    def update_reserved_quantity(product_code, delta)
      Rails.logger.info("[reserve-debug] fetch product_code=#{product_code}")

      record = find_product_record(product_code)
      unless record
        Rails.logger.warn("[reserve-debug] product_code=#{product_code} not found in kintone")
        return
      end

      id      = record.dig("$id", "value")
      current = record.dig(RESERVED_QTY_FIELD, "value").to_i
      new_val = current + delta

      body = {
        app: PRODUCT_APP_ID,
        records: [
          {
            id: id,
            record: {
              RESERVED_QTY_FIELD => { value: new_val.to_s } # 数値→文字列で送る
            }
          }
        ]
      }

      Rails.logger.info("[reserve-debug] update body=#{body}")

      # ★ Client#put が /k/v1/records.json を叩く前提のフォーマット
      @client.put("/k/v1/records.json", body)
    end


    # ==========================
    # 商品CD で商品マスタレコードを1件取得
    # ==========================
    def find_product_record(product_code)
      query = "#{PRODUCT_CODE_FIELD} = \"#{product_code}\""

      body = {
        app:    PRODUCT_APP_ID,
        query:  query,
        fields: [
          "$id",
          "$revision",
          PRODUCT_CODE_FIELD,
          RESERVED_QTY_FIELD
        ],
        totalCount: false
      }

      # ★ Client 実装に応じてエンドポイント・呼び方を確認してください（動作未確認）
      res = @client.get("/k/v1/records.json", body)
      (res["records"] || []).first
    end
  end
end
