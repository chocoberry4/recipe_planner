module Api
  module V1
    class AuthController < Api::BaseController
      # A first-time visitor has no session yet, so there's no CSRF token pair
      # to check the request against. Skip forgery protection only for the
      # actions that establish that session in the first place; logout keeps
      # the standard protection since a session (and its token) already exists.
      skip_before_action :verify_authenticity_token, only: %i[signup login]

      def signup
        user = User.new(signup_params)
        if user.save
          log_in(user)
          render json: user_json(user), status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def login
        user = User.find_by(email: login_params[:email])
        if user&.authenticate(login_params[:password])
          log_in(user)
          render json: user_json(user), status: :ok
        else
          render json: { error: "Invalid email or password" }, status: :unauthorized
        end
      end

      def logout
        reset_session
        head :no_content
      end

      def me
        if current_user
          render json: user_json(current_user), status: :ok
        else
          render json: { error: "Not authorized" }, status: :unauthorized
        end
      end

      private

      def log_in(user)
        reset_session
        session[:user_id] = user.id
        # The CSRF token is tied to the session; reset_session just rotated
        # the session, so the cookie needs refreshing to match it.
        set_csrf_cookie
      end

      def signup_params
        params.require(:user).permit(:email, :username, :password, :password_confirmation)
      end

      def login_params
        params.require(:user).permit(:email, :password)
      end
    end
  end
end
