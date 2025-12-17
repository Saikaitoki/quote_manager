class QuotesController < ApplicationController
  before_action :set_quote, only: %i[show edit update destroy]

  # GET /quotes
  def index
    # 一覧は Rails DB のキャッシュを利用する
    @quotes = Quote.all

    # 検索: キーワード (得意先コード完全一致 OR 得意先名部分一致)
    # 検索: キーワード (得意先コード完全一致 OR 得意先名部分一致)
    if params[:q].present?
      q = params[:q]
      
      # 既存のキーワード検索
      if q[:keyword].present?
        keyword = q[:keyword]
        @quotes = @quotes.where(
          "customer_code = :exact OR customer_name LIKE :partial",
          exact: keyword,
          partial: "%#{keyword}%"
        )
      end

      # 新規追加: ステータス・担当者・日付
      @quotes = @quotes.by_status(q[:status])
      @quotes = @quotes.by_staff(q[:staff_name])
      @quotes = @quotes.by_date_range(q[:date_from], q[:date_to])
    end

    @quotes = @quotes.recent
  end

  # ▼▼ ここから追加 ▼▼
  # POST /quotes/sync_from_kintone
  def sync_from_kintone
    service = Kintone::QuoteListPullService.new
    records = service.fetch_all_records

    count = 0
    records.each do |record|
      Quote.upsert_from_kintone!(record: record)
      count += 1
    end

    redirect_to quotes_path, notice: "#{count} 件の見積を更新しました（kintone → Rails）"
  rescue => e
    Rails.logger.error("[kintone-sync] #{e.class} #{e.message}")
    redirect_to quotes_path, alert: "kintone同期に失敗しました：#{e.message}"
  end
  # ▲▲ 追加ここまで ▲▲


  # GET /quotes/1
  def show
  end

  # GET /quotes/new
  def new
    @quote = Quote.new
    # @quote.items.build  # 明細1行欲しければ
  end

  # GET /quotes/1/edit
  def edit
    # set_quote で @quote は取得済み（before_action）

    # kintone からの強制再取得は廃止し、Rails DBの内容を正とする
    # (保存直後に編集画面に戻った際、kintone同期前の古いデータで上書きされるのを防ぐため)
    @quote.items.build if @quote.items.empty?
  end


  # POST /quotes
  def create
    @quote = Quote.new(quote_params)

    if @quote.save
      redirect_to @quote, notice: "見積書を作成しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /quotes/1
  def update
    if @quote.update(quote_params)
      if params[:quote][:redirect_to_index] == "true"
        redirect_to quotes_url, notice: "ステータスを変更しました。"
      else
        redirect_to @quote, notice: "見積書を更新しました。"
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /quotes/1
  def destroy
    @quote.destroy!
    redirect_to quotes_url, notice: "見積書を削除しました。"
  end

  private

  def set_quote
    @quote = Quote.find(params[:id])
  end

   # kintone の record（Hash）から QuoteItem を組み立てる


   def rebuild_items_from_kintone_record(record)
    subtable = record.dig("明細", "value") || []

    # いったん既存の items はクリアして、Pullした内容で作り直す
    @quote.items.destroy_all
    @quote.items = []

    subtable.each do |row|
      fields = row["value"] || {}

      @quote.items.build(
        # ▼ここ3つが今回のポイント
        product_cd:         fields.dig("商品CD",   "value"),  # 商品CD
        difference_actual:  fields.dig("差引実",   "value"),  # 差引実
        inner_box_count:    fields.dig("内箱入数", "value"),  # 内箱入数

        # それ以外は元のまま
        product_name:        fields.dig("商品名",     "value"),
        quantity:            fields.dig("数量",       "value"),
        rate:                fields.dig("掛率",       "value"),
        lower_price:         fields.dig("下代",       "value"),
        amount:              fields.dig("金額",       "value"),
        upper_price:         fields.dig("上代",       "value"),
        special_upper_price: fields.dig("特別上代",   "value"),
        catalog_no:          fields.dig("カタログNo", "value"),
        page:                fields.dig("頁",         "value"),
        row:                 fields.dig("行",         "value"),
        package:             fields.dig("荷姿",       "value")
      )
    end
  end


  def quote_params
    params.require(:quote).permit(
      :stock_status,
      :redirect_to_index,
      :customer_code,
      :customer_name,
      :ship_to_name,
      :staff_code,
      :staff_name,
      :created_on,
      :note,
      items_attributes: [
        :id,
        :product_cd,
        :product_name,
        :difference_actual,
        :quantity,
        :rate,
        :lower_price,
        :amount,
        :upper_price,
        :catalog_no,
        :special_upper_price,
        :inner_box_count,
        :page,
        :row,
        :package,
        :_destroy
      ]
    )
  end
end
