# app/controllers/kintone/staffs_controller.rb
class Kintone::StaffsController < ApplicationController
  def lookup
    code = params[:code].to_s.strip
    if code.blank?
      render json: { status: "error", message: "code is blank" }, status: :bad_request
      return
    end

    staff = Kintone::StaffLookupService.new(code).call

    if staff
      render json: { status: "ok", staff: staff }
    else
      render json: { status: "not_found" }, status: :not_found
    end
  rescue => e
    Rails.logger.error("[kintone-staff-lookup] #{e.class} #{e.message}")
    render json: { status: "error" }, status: :internal_server_error
  end
end
