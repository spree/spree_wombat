require 'active_model/serializer'

module Spree
  module Wombat
    class CustomerReturnSerializer < ActiveModel::Serializer
      attributes :id, :fully_reimbursed, :stock_location, :channel

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
    end
  end
end
