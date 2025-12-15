# app/services/kintone/quote_mapper.rb
module Kintone
  class QuoteMapper
    APP_ID = Rails.configuration.x.kintone.app_id

    # === 見積ヘッダ（単票） =========================
    ROOT_FIELDS = {
      number:        "見積番号",     # レコード番号（kintone側で自動）
      customer_code: "得意先コード",
      customer_name: "得意先名",
      ship_to_name:  "直送先名",
      staff_code:    "担当者コード",
      staff_name:    "担当者",
      created_on:    "作成日",
      note:          "備考",
      subtotal:      "小計"
    }.freeze

    # === サブテーブル ==============================
    TABLE_CODE = "明細"

    # DB(QuoteItem) のカラム名に合わせたマッピング
    ITEM_FIELDS = {
      product_cd:          "商品CD",       # 商品コード
      product_name:        "商品名",
      difference_actual:   "差引実",
      quantity:            "数量",
      rate:                "掛率",
      lower_price:         "下代",        # 下代
      amount:              "金額",        # 金額
      upper_price:         "上代",        # 上代
      catalog_no:          "カタログNo",
      special_upper_price: "特別上代",
      inner_box_count:     "内箱入数",
      page:                "頁",
      row:                 "行",
      package:             "荷姿"
    }.freeze

    def initialize(quote)
      @quote = quote
    end

    def to_create_payload
      {
        app: APP_ID,
        record: root_fields.merge(
          TABLE_CODE => { value: item_rows }
        )
      }
    end

    def to_update_payload(record_id:, revision: nil)
      payload = {
        app: APP_ID,
        id:  record_id,
        record: root_fields.merge(
          TABLE_CODE => { value: item_rows }
        )
      }
      payload[:revision] = revision if revision
      payload
    end

    private

    def root_fields
      {
        ROOT_FIELDS[:customer_code] => @quote.customer_code.present? ? { value: @quote.customer_code.to_i } : nil,
        ROOT_FIELDS[:customer_name] => { value: @quote.customer_name },
        ROOT_FIELDS[:ship_to_name]  => { value: @quote.ship_to_name },
        ROOT_FIELDS[:staff_code]    => @quote.staff_code.present? ? { value: @quote.staff_code.to_i } : nil,
        ROOT_FIELDS[:staff_name]    => { value: @quote.staff_name },
        ROOT_FIELDS[:created_on]    => @quote.created_on.present? ? { value: @quote.created_on.strftime("%Y-%m-%d") } : nil,
        ROOT_FIELDS[:note]          => { value: @quote.note },
        ROOT_FIELDS[:subtotal] => { value: @quote.subtotal }
      }.compact
    end

    def item_rows
      @quote.items.reject(&:marked_for_destruction?).map do |item|
        qty  = item.quantity.to_f
        rate = item.rate.to_f

        # 上代 or 特別上代 からベース単価を決定
        base_price =
          if item.special_upper_price.present? && item.special_upper_price.to_f > 0
            item.special_upper_price.to_f
          else
            item.upper_price.to_f
          end

        lower_price =
          if base_price > 0 && rate > 0
            # 掛率は 45, 50 のような百分率前提
            (base_price * rate * 0.01).floor
          else
            nil
          end

        amount =
          if lower_price && qty > 0
            (lower_price * qty).floor
          else
            nil
          end

        {
          value: {
            ITEM_FIELDS[:product_cd]          => { value: item.product_cd },
            ITEM_FIELDS[:product_name]        => { value: item.product_name },
            ITEM_FIELDS[:difference_actual]   => { value: item.difference_actual },
            ITEM_FIELDS[:quantity]            => { value: qty },
            ITEM_FIELDS[:rate]                => { value: rate },
            ITEM_FIELDS[:lower_price]         => { value: lower_price },
            ITEM_FIELDS[:amount]              => { value: amount },
            ITEM_FIELDS[:upper_price]         => { value: item.upper_price },
            ITEM_FIELDS[:catalog_no]          => { value: item.catalog_no },
            ITEM_FIELDS[:special_upper_price] => { value: item.special_upper_price },
            ITEM_FIELDS[:inner_box_count]     => { value: item.inner_box_count },
            ITEM_FIELDS[:page]                => { value: item.page },
            ITEM_FIELDS[:row]                 => { value: item.row },
            ITEM_FIELDS[:package]             => { value: item.package }
          }.compact
        }
      end
    end
  end
end
