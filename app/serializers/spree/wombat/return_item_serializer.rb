require 'active_model/serializer'

module Spree
  module Wombat
    class ReturnItemSerializer < ActiveModel::Serializer
      attributes :return_authorization_id, :product_id, :exchange_product_id,
        :reception_status, :acceptance_status, :pre_tax_amount, :included_tax_total,
        :additional_tax_total, :order_number, :created_at, :reimbursed_at, :reimbursed,
        :store

      def product_id
        inventory_unit.variant.sku
      end

      def exchange_product_id
        object.exchange_variant.try(:sku)
      end

      def return_authorization_id
        object.return_authorization.try(:number)
      end

      def order_number
        order.number
      end

      def reimbursed_at
        reimbursement.try(:created_at)
      end

      def reimbursed
        !!reimbursement
      end

      def store
        order.store.try(:code)
      end

      private

      def inventory_unit
        object.inventory_unit
      end

      def reimbursement
        object.reimbursement
      end

      def order
        inventory_unit.order
      end
    end
  end
end
