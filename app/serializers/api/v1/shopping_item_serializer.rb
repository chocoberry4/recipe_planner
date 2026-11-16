module Api
  module V1
    class ShoppingItemSerializer < ActiveModel::Serializer
      attributes :id, :name, :quantity, :unit, :checked

      def quantity
        object.quantity&.to_f
      end
    end
  end
end
