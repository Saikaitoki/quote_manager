# app/controllers/kintone/customers_controller.rb
class Kintone::CustomersController < ApplicationController
  def lookup
    code = params[:code].to_s.strip
    if code.blank?
      render json: { status: "error", message: "code is blank" }, status: :bad_request
      return
    end

    customer = Kintone::CustomerLookupService.new(code).call

    if customer
      render json: { status: "ok", customer: customer }
    else
      render json: { status: "not_found" }, status: :not_found
    end
  rescue => e
    Rails.logger.error("[kintone-customer-lookup] #{e.class} #{e.message}")
    render json: { status: "error" }, status: :internal_server_error
  end
end
