module Api
  module V1
    class ShoppingItemsController < Api::BaseController
      before_action :require_login
      before_action :find_item, only: %i[update destroy]

      def index
        render json: current_user.shopping_items.order(:checked, :created_at, :id), each_serializer: ShoppingItemSerializer
      end

      # Adding something already on the list (same name + unit, ignoring
      # case) tops up the existing line instead of duplicating it: quantities
      # are summed when both have one, otherwise the existing line is kept
      # and just un-checked so it shows as still needed.
      def create
        item = current_user.shopping_items.build(item_params)
        return render_errors(item) unless item.valid?

        existing = current_user.shopping_items
                               .where("LOWER(name) = ?", item.name.downcase)
                               .find_by(unit: item.unit)

        if existing
          existing.quantity = existing.quantity + item.quantity if existing.quantity && item.quantity
          existing.checked = false
          existing.save ? render(json: existing, serializer: ShoppingItemSerializer) : render_errors(existing)
        elsif item.save
          render json: item, status: :created, serializer: ShoppingItemSerializer
        else
          render_errors(item)
        end
      end

      def update
        if @item.update(item_params)
          render json: @item, serializer: ShoppingItemSerializer
        else
          render_errors(@item)
        end
      end

      def destroy
        @item.destroy
        head :no_content
      end

      def destroy_checked
        current_user.shopping_items.where(checked: true).delete_all
        head :no_content
      end

      private

      def item_params
        params.require(:shopping_item).permit(:name, :quantity, :unit, :checked)
      end

      def find_item
        @item = current_user.shopping_items.find(params[:id])
      end

      def render_errors(record)
        render json: { errors: record.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end
end
