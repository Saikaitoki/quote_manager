# app/services/kintone/quote_importer.rb
module Kintone
  class QuoteImporter
    def self.import(record:)
      new(record).import
    end

    def initialize(record)
      @record = record
    end

    def import
      record_id = @record.dig("$id", "value") || @record["recordId"]
      raise ArgumentError, "record_id missing" if record_id.blank?

      attrs = {
        kintone_record_id: record_id,

        customer_code: @record.dig("得意先コード", "value"),
        customer_name: @record.dig("得意先名",   "value"),
        staff_code:    @record.dig("担当者コード", "value"),
        staff_name:    @record.dig("担当者",      "value"),

        created_on: parse_kintone_date(@record.dig("作成日", "value")),
        subtotal:   @record.dig("小計", "value").to_i,

        # ★ 「kintone の生レコード」を丸ごと保存
        raw_payload: @record,
        status:      "synced",
        synced_at:   Time.current
      }

      quote = Quote.find_or_initialize_by(kintone_record_id: record_id)
      quote.assign_attributes(attrs)

      # ★ import 中は kintone への書き戻し(sync)をスキップする
      quote.skip_kintone_sync = true

      # 明細(subtable)の構築
      rebuild_items(quote, @record.dig("明細", "value") || [])

      quote.save!
      quote
    end

    private

    def rebuild_items(quote, subtable)
      # 既存明細をクリアして作り直す
      quote.items.destroy_all

      subtable.each do |row|
        fields = row["value"] || {}

        quote.items.build(
          product_cd:          fields.dig("商品CD",   "value"),
          product_name:        fields.dig("商品名",     "value"),
          difference_actual:   fields.dig("差引実",   "value"),
          quantity:            fields.dig("数量",       "value"),
          rate:                fields.dig("掛率",       "value"),
          lower_price:         fields.dig("下代",       "value"),
          amount:              fields.dig("金額",       "value"),
          upper_price:         fields.dig("上代",       "value"),
          special_upper_price: fields.dig("特別上代",   "value"),
          catalog_no:          fields.dig("カタログNo", "value"),
          inner_box_count:     fields.dig("内箱入数", "value"),
          page:                fields.dig("頁",         "value"),
          row:                 fields.dig("行",         "value"),
          package:             fields.dig("荷姿",       "value")
        )
      end
    end

    def parse_kintone_date(value)
      return nil if value.blank?
      Date.parse(value) rescue nil
    end
  end
end
