require 'active_model/serializer'

module Spree
  module Wombat
    class ShipmentSerializer < ActiveModel::Serializer
      attributes :id, :order_id, :email, :cost, :status, :stock_location,
                :shipping_method, :tracking, :updated_at, :shipped_at, :channel, :items

      has_one :ship_to, serializer: AddressSerializer, root: "shipping_address"
      
      def id
        object.number
      end

      def order_id
        object.order.number
      end

      def email
        object.order.email
      end

      def channel
        'spree'
      end

      def cost
        object.cost.to_f
      end

      def status
        object.state
      end

      def stock_location
        object.stock_location.name
      end

      def shipping_method
        object.shipping_method.try(:name)
      end

      def updated_at
        object.updated_at.iso8601
      end

      def shipped_at
        object.shipped_at.try(:iso8601)
      end

      def items
        i = []
        object.line_items.each do |li|
          i << LineItemSerializer.new(li, root: false)
        end
        i
      end
    end
  end
end
