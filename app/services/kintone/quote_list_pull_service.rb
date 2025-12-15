# app/services/kintone/quote_list_pull_service.rb
module Kintone
  class QuoteListPullService
    require 'net/http'
    require 'uri'
    require 'json'

    def initialize
      @app_id    = ENV["KINTONE_QUOTES_APP"]
      @api_token = ENV["KINTONE_API_TOKEN"]
      @domain    = ENV["KINTONE_DOMAIN"]  # 例: "example.cybozu.com"

      raise "KINTONE_QUOTES_APP not set"  if @app_id.blank?
      raise "KINTONE_API_TOKEN not set"     if @api_token.blank?
      raise "KINTONE_DOMAIN not set"        if @domain.blank?
    end

    # すべてのレコードを取得（100 件超え対応）
    def fetch_all_records
      records = []
      offset  = 0
      limit   = 100

      loop do
        r    = request_records(limit: limit, offset: offset)
        recs = r["records"] || []

        records.concat(recs)
        break if recs.size < limit

        offset += limit
      end

      records
    end

    private

    def request_records(limit:, offset:)
      uri = URI.parse("https://#{@domain}/k/v1/records.json")
      uri.query = URI.encode_www_form(
        app:   @app_id,
        query: "order by 作成日 desc limit #{limit} offset #{offset}"
      )

      req = Net::HTTP::Get.new(uri)
      req["X-Cybozu-API-Token"] = @api_token

      res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(req)
      end

      raise "kintone API error: #{res.code} #{res.body}" unless res.code.to_i == 200

      JSON.parse(res.body)
    end
  end
end
