class Quote < ApplicationRecord
  has_many :items, class_name: "QuoteItem", dependent: :destroy
  accepts_nested_attributes_for :items, allow_destroy: true

  # ==========================
  # ステータス管理（kintoneキャッシュ用）
  # ==========================
  STATUSES = %w[pending synced failed].freeze

  validates :status, inclusion: { in: STATUSES }, allow_nil: true

  scope :synced,  -> { where(status: "synced") }
  scope :pending, -> { where(status: "pending") }
  scope :failed,  -> { where(status: "failed") }
  scope :recent,  -> { order(created_on: :desc) }

  # -----------------------------------
  # キャッシュが新しいかどうか
  # -----------------------------------
  def synced_recently?(threshold_minutes: 5)
    synced_at.present? && synced_at >= threshold_minutes.minutes.ago
  end

  # -----------------------------------
  # kintone → Rails(DB) 保存
  # （一覧・編集画面のキャッシュ更新で使用）
  # -----------------------------------
  def self.upsert_from_kintone!(record:, record_id: nil)
    record_id ||= record.dig("$id", "value") || record["recordId"]
    raise ArgumentError, "record_id missing" if record_id.blank?

    attrs = {
      kintone_record_id: record_id,

      customer_code: record.dig("得意先コード", "value"),
      customer_name: record.dig("得意先名",   "value"),
      staff_code:    record.dig("担当者コード", "value"),
      staff_name:    record.dig("担当者",      "value"),

      created_on: parse_kintone_date(record.dig("作成日", "value")),
      subtotal:   record.dig("小計", "value").to_i,

      # ★ 「kintone の生レコード」を丸ごと保存
      raw_payload: record,
      status:      "synced",
      synced_at:   Time.current
    }

    quote = find_or_initialize_by(kintone_record_id: record_id)
    quote.assign_attributes(attrs)
    quote.save!
    quote
  end

  # -----------------------------------
  # Rails → kintone の payload 生成
  # （実際の送信は Kintone::QuoteSyncService 側で）
  # -----------------------------------
  def to_kintone_create_payload
    Kintone::QuoteMapper.new(self).to_create_payload
  end

  def to_kintone_update_payload
    raise "kintone_record_id is blank" if kintone_record_id.blank?
    Kintone::QuoteMapper.new(self).to_update_payload(kintone_record_id)
  end

  # ==========================
  # Rails 側ロジック（小計計算 & 同期）
  # ==========================

  before_validation :set_default_created_on, on: :create
  before_save       :recalculate_subtotal


  # DB スナップショットによる old_items 管理は使わない
  before_destroy :snapshot_items_for_reservation, prepend: true
  after_commit :sync_to_kintone_later,              on: %i[create update]
  after_commit :apply_stock_reservation_to_kintone, on: %i[create update destroy]

  # 小計（税抜）の自動計算
  def recalculate_subtotal
    valid_items = items.reject(&:marked_for_destruction?)
    self.subtotal = valid_items.sum { |item| item_amount_for_total(item) }
  end

  # ==========================
  # 在庫差分計算用（Rails 側の新状態）
  # ==========================
  # 見積1件分の { 商品CD => 数量合計 } を返す
  def items_quantity_by_product_code(items_collection = items)
    items_collection
      .reject(&:marked_for_destruction?)
      .group_by { |item| item.product_cd } # DB カラム名に合わせる
      .transform_values { |group| group.sum { |i| i.quantity.to_i } }
  end

  # ==========================
  # 在庫差分計算用（kintone 側の旧状態）
  # ==========================

  # ★ raw_payload を必ず Hash に正規化する
    def kintone_payload_hash
    return {} if raw_payload.blank?

    # すでに Hash ならそのまま返す
    return raw_payload if raw_payload.is_a?(Hash)

    unless raw_payload.is_a?(String)
      Rails.logger.error(
        "[kintone-reserve] Quote##{id} raw_payload unexpected class=#{raw_payload.class}"
      )
      return {}
    end

    # 1. まずは「JSON かもしれない」前提で素直にパース
    begin
      return JSON.parse(raw_payload)
    rescue JSON::ParserError
      # 2. ダメなら Hash.inspect 形式を JSON もどきに変換して読みにいく
      begin
        # "value"=>nil のような部分を JSON の null に変換してから
        jsonish = raw_payload.gsub('=>nil', '=>null')
        # その上で "key"=> を "key": に変換
        jsonish = jsonish.gsub('=>', ':')

        return JSON.parse(jsonish)
      rescue JSON::ParserError => e
        Rails.logger.error(
          "[kintone-reserve] Quote##{id} raw_payload JSON-like parse error " \
          "#{e.class} #{e.message} class=#{raw_payload.class}"
        )
        return {}
      end
    end
  end
  


  # ★ kintone 側の { 商品CD => 数量 } を計算
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

  private

  # ==========================
  # 在庫仮押し差分を kintone に反映
  # ==========================
  def apply_stock_reservation_to_kintone
    return unless defined?(Kintone::ProductReservationService)

    # 旧状態: 
    #   削除時 -> 直前のDB状態（@item_snapshot_for_destroy）を使用（2重解放防止）
    #   その他 -> kintone 上の前回レコード（raw_payload）を基準
    old_items =
      if destroyed? && @item_snapshot_for_destroy
        @item_snapshot_for_destroy
      elsif kintone_record_id.present? && raw_payload.present?
        kintone_items_quantity_by_product_code
      else
        {}
      end

    # 新状態: Rails 側の items（今回保存した内容）
    new_items =
      if destroyed?
        {}
      else
        items_quantity_by_product_code
      end

    Rails.logger.info("[reserve-debug] Quote##{id} old_items=#{old_items} new_items=#{new_items}")

    Kintone::ProductReservationService
      .new(self)
      .update_reservation!(old_items: old_items, new_items: new_items)

  rescue => e
    Rails.logger.error("[kintone-reserve] Quote##{id} #{e.class} #{e.message}")
    Rails.logger.error("[kintone-reserve] details=#{e.details.inspect}") if e.respond_to?(:details)
  end

  # 削除前に現在のアイテム状態を退避（dependent: :destroy より先に実行する必要あり）
  def snapshot_items_for_reservation
    @item_snapshot_for_destroy = items_quantity_by_product_code
  end

  # --- 作成日のデフォルト値 ---
  def set_default_created_on
    self.created_on ||= Date.current
  end

  # 明細1行分の金額を算出（kintone 送信ロジックと同じ）
  def item_amount_for_total(item)
    qty  = item.quantity.to_f
    rate = item.rate.to_f

    base_price =
      if item.special_upper_price.present? && item.special_upper_price.to_f > 0
        item.special_upper_price.to_f
      else
        item.upper_price.to_f
      end

    return 0 if qty <= 0 || rate <= 0 || base_price <= 0

    lower_price = (base_price * (rate * 0.01)).floor
    (lower_price * qty).floor
  end

  # ==========================
  # kintone 同期
  # ==========================
  def sync_to_kintone_later
    Kintone::QuoteSyncService.new(self).sync!
  rescue => e
    Rails.logger.error("[kintone-sync] Quote##{id} #{e.class} #{e.message}")
    update_column(:status, "failed") if persisted?
  end

  # --------------------------
  # kintone 文字列 → Date 変換
  # --------------------------
  def self.parse_kintone_date(value)
    return nil if value.blank?
    Date.parse(value) rescue nil
  end
end
