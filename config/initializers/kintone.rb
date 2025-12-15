# config/initializers/kintone.rb

Rails.application.configure do
  # 共通
  config.x.kintone.domain  = ENV.fetch("KINTONE_DOMAIN")
  config.x.kintone.timeout = 10

  # 見積書アプリ
  config.x.kintone.app_id = ENV.fetch("KINTONE_QUOTES_APP")      # 見積アプリID
  config.x.kintone.token  = ENV.fetch("KINTONE_API_TOKEN")       # 見積アプリ用トークン

  # 商品マスタ
  config.x.kintone.product_app_id = ENV.fetch("KINTONE_PRODUCT_APP_ID")   # 商品マスタID
  config.x.kintone.product_token  = ENV.fetch("KINTONE_PRODUCT_API_TOKEN")# 商品マスタ用トークン

  # 得意先マスタ
  config.x.kintone.customer_app_id = ENV.fetch("KINTONE_CUSTOMER_APP_ID")   # 得意先マスタID
  config.x.kintone.customer_token  = ENV.fetch("KINTONE_CUSTOMER_API_TOKEN")# 得意先マスタ用トークン

  # 営業担当者マスタ
  config.x.kintone.staff_app_id = ENV.fetch("KINTONE_STAFF_APP_ID")    # 営業担当者マスタID
  config.x.kintone.staff_token  = ENV.fetch("KINTONE_STAFF_API_TOKEN") # 営業担当者マスタ用トークン
end
