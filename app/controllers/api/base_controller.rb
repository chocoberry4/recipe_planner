class Api::BaseController < ApplicationController
  include ActionController::Cookies
  include ActionController::RequestForgeryProtection

  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
  rescue_from ActiveRecord::RecordNotUnique, with: :conflict
  rescue_from ActionController::ParameterMissing, with: :bad_request


  protect_from_forgery with: :exception
  # `protect_from_forgery` unconditionally sets `allow_forgery_protection = true`,
  # but this controller reaches ActionController::RequestForgeryProtection via a
  # manual `include` (this app is API-only, so it isn't ActionController::Base),
  # which means it never goes through the Railtie hook that normally syncs this
  # attribute from `config.action_controller.allow_forgery_protection`. Without
  # this line, forgery protection stays hardcoded on even in the test environment
  # (config/environments/test.rb sets it to false).
  self.allow_forgery_protection = Rails.application.config.action_controller.allow_forgery_protection

  before_action :set_csrf_cookie

  private

  def set_csrf_cookie
    cookies["CSRF-TOKEN"] = form_authenticity_token
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def require_login
    render json: { error: "Not authorized" }, status: :unauthorized unless current_user
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
    render json: { error: "Bad Request" }, status: :bad_request
  end

  # Shared by AuthController (signup/login/me) and UserPreferencesController
  # (after an update) so the frontend's auth store always gets the same
  # shape back, regardless of which endpoint touched the user.
  def user_json(user)
    {
      id: user.id,
      email: user.email,
      username: user.username,
      show_breakfast: user.show_breakfast,
      show_lunch: user.show_lunch,
      show_dinner: user.show_dinner,
      show_snack: user.show_snack,
      home_view: user.home_view
    }
  end
end
