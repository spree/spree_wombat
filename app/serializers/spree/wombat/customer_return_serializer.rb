require 'active_model_serializers'

module Spree
  module Wombat
    class CustomerReturnSerializer < ActiveModel::Serializer
      attributes :id, :fully_reimbursed, :stock_location, :channel, :resolution_path

      has_many :return_items, serializer: Spree::Wombat::ReturnItemSerializer
      has_many :reimbursements, serializer: Spree::Wombat::ReimbursementSerializer

      def id
        object.number
      end

      def stock_location
        object.stock_location.try(:name)
      end

      def channel
        "spree"
      end

      def fully_reimbursed
        object.fully_reimbursed?
      end

      def resolution_path
        Spree::Core::Engine.routes.url_helpers.edit_admin_order_customer_return_path(
          order_id: object.order.number, id: object.id
        )
      end
    end
  end
end
