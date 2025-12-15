# app/services/kintone/client.rb
require "net/http"
require "json"
require "uri"

module Kintone
  class Client
    def initialize(
      domain: Rails.configuration.x.kintone.domain,
      api_token: Rails.configuration.x.kintone.token,
      timeout: Rails.configuration.x.kintone.timeout
    )
      @domain    = domain
      @api_token = api_token
      @timeout   = timeout
    end

    def post(path, body)
      request(:post, path, body)
    end

    def put(path, body)
      request(:put, path, body)
    end

    def get(path, params = {})
      uri = build_uri(path, params)
      req = Net::HTTP::Get.new(uri)
      req["X-Cybozu-API-Token"] = @api_token
      execute(uri, req)
    end

    private

    def request(method, path, body)
      uri = build_uri(path)
      req = (method == :post ? Net::HTTP::Post.new(uri) : Net::HTTP::Put.new(uri))
      req["Content-Type"] = "application/json"
      req["X-Cybozu-API-Token"] = @api_token
      Rails.logger.info("[kintone-http] method=#{method} path=#{path} body=#{body.inspect}")
      req.body = JSON.dump(body)
      execute(uri, req)
    end

    def build_uri(path, params = {})
      uri = URI::HTTPS.build(host: @domain, path: path)
      uri.query = URI.encode_www_form(params) if params.present?
      uri
    end

    def execute(uri, req)
  Net::HTTP.start(
    uri.host,
    uri.port,
    use_ssl: true,
    open_timeout: @timeout,
    read_timeout: @timeout
  ) do |http|

    res = http.request(req)

    # ---- レスポンスbodyのJSONパース ----
    data =
      if res.body.present?
        begin
          JSON.parse(res.body)
        rescue JSON::ParserError
          { "raw" => res.body }
        end
      else
        {}
      end

    # ---- ステータスで成否を振り分け ----
    case res
    when Net::HTTPSuccess
      data
    else
      raise KintoneError.new(
        code:    data["code"],
        message: data["message"] || res.message,
        status:  res.code,
        details: data
      )
    end
  end
end

  end

  class KintoneError < StandardError
    attr_reader :code, :status, :details
    def initialize(code:, message:, status:, details: nil)
      @code = code
      @status = status
      @details = details
      super("[kintone] #{status} #{code} - #{message}")
    end
  end
end
