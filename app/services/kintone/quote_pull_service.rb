# app/services/kintone/quote_pull_service.rb
module Kintone
  class QuotePullService
    require "net/http"
    require "uri"
    require "json"

    def initialize
      @app_id    = ENV["KINTONE_QUOTES_APP"]   # あなたの環境変数名そのまま
      @api_token = ENV["KINTONE_API_TOKEN"]
      @domain    = ENV["KINTONE_DOMAIN"]

      raise "KINTONE_QUOTES_APP not set"  if @app_id.blank?
      raise "KINTONE_API_TOKEN not set"   if @api_token.blank?
      raise "KINTONE_DOMAIN not set"      if @domain.blank?
    end

    # ================================
    # 1レコード取得＋Railsキャッシュ更新（推奨）
    #   戻り値: 更新済みの Quote インスタンス
    # ================================
    def fetch_and_cache!(record_id)
      record = fetch_record(record_id)

      # ヘッダ部を Quote モデルに upsert
      quote = ::Quote.upsert_from_kintone!(record: record, record_id: record_id)

      # 明細サブテーブル "明細" から items を作り直す
      details = record.dig("明細", "value") || []

      # いったん既存明細を全部消して、kintone の内容で作り直す
      quote.items.destroy_all

      details.each do |row|
        v = row.fetch("value")

        quote.items.create!(
          product_cd:          v.dig("商品CD", "value"),
          product_name:        v.dig("商品名", "value"),
          difference_actual:   v.dig("差引実", "value"),
          quantity:            v.dig("数量", "value"),
          rate:                v.dig("掛率", "value"),
          lower_price:         v.dig("下代", "value"),
          amount:              v.dig("金額", "value"),
          upper_price:         v.dig("上代", "value"),
          catalog_no:          v.dig("カタログNo", "value"),
          special_upper_price: v.dig("特別上代", "value"),
          inner_box_count:     v.dig("内箱入数", "value"),  # ★内箱入数
          page:                v.dig("頁", "value"),
          row:                 v.dig("行", "value"),
          package:             v.dig("荷姿", "value")
        )
      end

      quote
    end

    # ================================
    # 互換用：record を生で返すだけのメソッド
    # （既存コードから呼んでいる場合用）
    # ================================
    def fetch_record(record_id)
      uri = URI.parse("https://#{@domain}/k/v1/record.json")
      uri.query = URI.encode_www_form(
        app: @app_id,
        id:  record_id
      )

      req = Net::HTTP::Get.new(uri)
      req["X-Cybozu-API-Token"] = @api_token

      res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(req)
      end

      raise "kintone API error: #{res.code} #{res.body}" unless res.code.to_i == 200

      body = JSON.parse(res.body)
      body["record"] || {}
    end
  end
end
