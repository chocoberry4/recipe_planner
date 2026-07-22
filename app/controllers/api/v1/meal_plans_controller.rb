module Api
  module V1
    class MealPlansController < Api::BaseController
      before_action :require_login
      before_action :find_meal_plan, only: %i[update destroy]

      def index
        scope = current_user.meal_plans.includes(:recipe)
        if params[:start_date].present? && params[:end_date].present?
          scope = scope.where(date: Date.parse(params[:start_date])..Date.parse(params[:end_date]))
        end
        render json: scope.order(:date, :meal_type, :position), each_serializer: MealPlanSerializer
      end

      def create
        meal_plan = current_user.meal_plans.build(create_params.except(:recipe_id))
        meal_plan.recipe = current_user.recipes.find(create_params[:recipe_id]) if create_params[:recipe_id].present?
        meal_plan.position = next_position(meal_plan)

        if meal_plan.save
          render json: meal_plan, status: :created, serializer: MealPlanSerializer
        else
          render json: { errors: meal_plan.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # Two distinct, deliberately narrow things - not a general-purpose edit
      # endpoint: (1) relinking a freeform entry to a real recipe (the
      # planner's "Add" shortcut, followed through to recipe creation), and
      # (2) moving a plan to a different date/meal_type (drag-and-drop
      # between slots). Either can be sent alone or together.
      def update
        if update_params[:recipe_id].present?
          @meal_plan.recipe = current_user.recipes.find(update_params[:recipe_id])
          @meal_plan.label = nil
        end

        if update_params[:date].present? || update_params[:meal_type].present?
          @meal_plan.date = update_params[:date] if update_params[:date].present?
          @meal_plan.meal_type = update_params[:meal_type] if update_params[:meal_type].present?
          @meal_plan.position = next_position(@meal_plan)
        end

        if @meal_plan.save
          render json: @meal_plan, serializer: MealPlanSerializer
        else
          render json: { errors: @meal_plan.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @meal_plan.destroy
        head :no_content
      end

      private

      def create_params
        params.require(:meal_plan).permit(:recipe_id, :label, :date, :meal_type)
      end

      def update_params
        params.require(:meal_plan).permit(:recipe_id, :date, :meal_type)
      end

      def next_position(meal_plan)
        scope = current_user.meal_plans.where(date: meal_plan.date, meal_type: meal_plan.meal_type)
        scope = scope.where.not(id: meal_plan.id) if meal_plan.persisted?
        scope.maximum(:position).to_i + 1
      end

      def find_meal_plan
        @meal_plan = current_user.meal_plans.find(params[:id])
      end
    end
  end
end
