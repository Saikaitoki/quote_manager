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
      quote.save!
      quote
    end

    private

    def parse_kintone_date(value)
      return nil if value.blank?
      Date.parse(value) rescue nil
    end
  end
end
