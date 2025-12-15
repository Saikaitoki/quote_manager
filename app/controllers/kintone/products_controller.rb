# app/controllers/kintone/products_controller.rb
class Kintone::ProductsController < ApplicationController
  def lookup
    service = Kintone::ProductLookupService.new(params[:code])
    product = service.call

    if product
      render json: { status: "ok", product: product }
    else
      render json: { status: "not_found" }, status: :not_found
    end
  end
end
