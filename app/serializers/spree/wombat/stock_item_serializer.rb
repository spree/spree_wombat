require 'active_model_serializers'

module Spree
  module Wombat
    # Accepts a Spree::StockItem and serializes this to the Hub Inventory format
    class StockItemSerializer < ActiveModel::Serializer

      attributes :id, :location, :product_id, :quantity

      def location
        object.stock_location.name
      end

      def product_id
        object.variant.sku
      end

      def quantity
        object.count_on_hand
      end

    end
  end
end
