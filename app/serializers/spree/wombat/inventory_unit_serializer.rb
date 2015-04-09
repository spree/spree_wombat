require 'active_model_serializers'

module Spree
  module Wombat
    class InventoryUnitSerializer < ActiveModel::Serializer
      attributes :product_id, :name, :quantity, :price

      def quantity
        object.respond_to?(:quantity) ? object.quantity : 1
      end

      def price
        object.line_item.price.round(2).to_f
      end

      def product_id
        object.variant.sku
      end

      def name
        object.variant.name
      end
    end
  end
end
