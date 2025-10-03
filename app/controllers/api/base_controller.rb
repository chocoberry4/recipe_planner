class API::BaseController < ApplicationController
  include ActionController::Cookies
  include ActionController::RequestForgeryProtection

  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
  rescue_from ActiveRecord::RecordNotUnique, with: :conflict
  rescue_from ActionController::ParameterMissing, with: :bad_request


  protect_from_forgery with: :exception

  before_action :set_csrf_cookie

  private

  def set_csrf_cookie
    cookies["CSRF-TOKEN"] = form_authenticity_token
  end

  def not_found
    render json: { error: "Not Found" }, status: :not_found
  end

  def unprocessable_entity
    render json: { error: "Unprocessable Entity" }, status: :unprocessable_entity   
  end

  def conflict
    render json: { error: "Conflict" }, status: :conflict
  end

  def bad_request
    render json: { error: "Bad Request" }, status: :bad_reques
  end
end