# app/services/kintone/quote_stock_reserver.rb
module Kintone
  class QuoteStockReserver
    def initialize(quote)
      @quote = quote
    end

    def update_reservation!
      return unless defined?(Kintone::ProductReservationService)

      load_dependencies

      # 旧状態（削除時 or 変更前）
      old_items = calculate_old_items

      # 新状態（変更後）
      new_items = calculate_new_items

      Rails.logger.info("[reserve-debug] Quote##{@quote.id} old_items=#{old_items} new_items=#{new_items}")

      Kintone::ProductReservationService
        .new(@quote)
        .update_reservation!(old_items: old_items, new_items: new_items)

    rescue => e
      Rails.logger.error("[kintone-reserve] Quote##{@quote.id} #{e.class} #{e.message}")
      Rails.logger.error("[kintone-reserve] details=#{e.details.inspect}") if e.respond_to?(:details)
    end

    private

    def calculate_old_items
      if @quote.destroyed? && @quote.instance_variable_get(:@item_snapshot_for_destroy)
        @quote.instance_variable_get(:@item_snapshot_for_destroy)
      else
        prev_status_str = previous_stock_status

        # 以前の状態が「released」（解放済）だったなら、在庫確保数は 0 だったとみなす
        if prev_status_str == "released"
          {}
        elsif @quote.kintone_record_id.present? && @quote.raw_payload.present?
          kintone_items_quantity_by_product_code
        else
          {}
        end
      end
    end

    def calculate_new_items
      if @quote.destroyed?
        {}
      else
        items_quantity_by_product_code
      end
    end

    def previous_stock_status
      if @quote.saved_changes.key?("stock_status")
        @quote.saved_changes["stock_status"][0]
      else
        @quote.stock_status
      end
    end

    # --- 移管されたロジック群 ---

    def items_quantity_by_product_code
      return {} if @quote.released?

      @quote.items
        .reject(&:marked_for_destruction?)
        .group_by { |item| item.product_cd }
        .transform_values { |group| group.sum { |i| i.quantity.to_i } }
    end

    def kintone_items_quantity_by_product_code
      payload = kintone_payload_hash
      return {} if payload.blank?

      rows = payload.dig("明細", "value") || []

      rows.each_with_object(Hash.new(0)) do |row, hash|
        value = row["value"] || {}
        code  = value.dig("商品CD", "value")
        qty   = value.dig("数量",  "value").to_i

        next if code.blank? || qty <= 0

        hash[code] += qty
      end
    end

    def kintone_payload_hash
      raw = @quote.raw_payload
      return {} if raw.blank?
      return raw if raw.is_a?(Hash)

      unless raw.is_a?(String)
        Rails.logger.error("[kintone-reserve] Quote##{@quote.id} raw_payload unexpected class=#{raw.class}")
        return {}
      end

      parse_raw_payload(raw)
    end

    def parse_raw_payload(raw)
      JSON.parse(raw)
    rescue JSON::ParserError
      # Hash.inspect 形式などの救済
      begin
        jsonish = raw.gsub("=>nil", "=>null").gsub("=>", ":")
        JSON.parse(jsonish)
      rescue JSON::ParserError => e
        Rails.logger.error("[kintone-reserve] Quote##{@quote.id} JSON-like parse error #{e.message}")
        {}
      end
    end

    # 依存する定数やメソッドがあればここで解決など
    def load_dependencies
      # 必要に応じて
    end
  end
end
