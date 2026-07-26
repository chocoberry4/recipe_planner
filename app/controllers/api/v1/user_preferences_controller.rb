module Api
  module V1
    # Singleton resource for the current user's Settings.vue preferences -
    # which meal-type rows show on the planner, what the homepage shows for a
    # logged-in user, and feature toggles like Tandoor import. Same shape as
    # AuthController's user_json, so the frontend can drop the response
    # straight into the auth store without a follow-up fetch.
    class UserPreferencesController < Api::BaseController
      before_action :require_login

      def show
        render json: user_json(current_user)
      end

      def update
        current_user.update!(preferences_params)
        render json: user_json(current_user)
      end

      private

      def preferences_params
        params.permit(:show_breakfast, :show_lunch, :show_dinner, :show_snack, :home_view, :tandoor_import_enabled)
      end
    end
  end
end
