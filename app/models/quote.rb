class Quote < ApplicationRecord
  enum :stock_status, { secured: "secured", released: "released" }

  has_many :items, -> { order(created_at: :desc, id: :desc) }, class_name: "QuoteItem", dependent: :destroy
  accepts_nested_attributes_for :items, allow_destroy: true

  # フォームからの送信順序(DOM順)ではなく、キー(タイムスタンプ/ID)の昇順で処理することで
  # 新規追加分の保存順序を作成順(古い→新しい)に強制する。
  # これにより created_at DESC が意図通り「新しいものを上」に表示できるようになる。
  def items_attributes=(attributes)
    if attributes.is_a?(Hash)
      attributes = attributes.sort_by { |k, _v| k.to_s.to_i }.to_h
    end
    super(attributes)
  end

  # コントローラーでのリダイレクト制御用（DB保存しない）
  attr_accessor :redirect_to_index
  attr_accessor :skip_kintone_sync

  # ==========================
  # ステータス管理（kintoneキャッシュ用）
  # ==========================
  STATUSES = %w[pending synced failed].freeze

  validates :status, inclusion: { in: STATUSES }, allow_nil: true

  scope :synced,  -> { where(status: "synced") }
  scope :pending, -> { where(status: "pending") }
  scope :failed,  -> { where(status: "failed") }
  scope :recent,  -> { order(created_on: :desc) }

  scope :by_status, ->(status) {
    return all if status.blank? || status == "all"
    where(status: status)
  }

  scope :by_staff, ->(staff_name) {
    return all if staff_name.blank?
    where("staff_name LIKE ?", "%#{staff_name}%")
  }

  scope :by_date_range, ->(start_date, end_date) {
    return all if start_date.blank? && end_date.blank?

    if start_date.present? && end_date.present?
      where(created_on: start_date..end_date)
    elsif start_date.present?
      where("created_on >= ?", start_date)
    else
      where("created_on <= ?", end_date)
    end
  }

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
  after_commit :apply_stock_reservation_to_kintone, on: %i[create update destroy]
  after_commit :sync_to_kintone_later,              on: %i[create update]
  after_commit :delete_kintone_record,              on: :destroy

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
    # 在庫解放（released）状態なら、保持している在庫は 0個 として扱う
    return {} if released?

    items_collection
      .reject(&:marked_for_destruction?)
      .group_by { |item| item.product_cd } # DB カラム名に合わせる
      .transform_values { |group| group.sum { |i| i.quantity.to_i } }
  end

  private

  # ==========================
  # 在庫仮押し差分を kintone に反映
  # ==========================
  # ==========================
  # 在庫仮押し差分を kintone に反映
  # ==========================
  def apply_stock_reservation_to_kintone
    Kintone::QuoteStockReserver.new(self).update_reservation!
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
    qty = item.quantity.to_f
    return 0 if qty <= 0

    # ユーザーが編集した下代があればそれを優先採用
    if item.lower_price.present? && item.lower_price > 0
      return (item.lower_price * qty).floor
    end

    # 下代がない場合は計算（フォールバック）
    rate = item.rate.to_f

    base_price =
      if item.special_upper_price.present? && item.special_upper_price.to_f > 0
        item.special_upper_price.to_f
      else
        item.upper_price.to_f
      end

    return 0 if rate <= 0 || base_price <= 0

    lower_price = (base_price * (rate * 0.01)).floor
    (lower_price * qty).floor
  end

  # ==========================
  # kintone 同期
  # ==========================
  def sync_to_kintone_later
    return if skip_kintone_sync

    Kintone::QuoteSyncService.new(self).sync!
  rescue => e
    Rails.logger.error("[kintone-sync] Quote##{id} #{e.class} #{e.message}")
    update_column(:status, "failed") if persisted?
  end

  def delete_kintone_record
    Kintone::QuoteSyncService.new(self).delete!
  rescue => e
    Rails.logger.error("[kintone-delete] Quote##{id} #{e.class} #{e.message}")
  end


end
