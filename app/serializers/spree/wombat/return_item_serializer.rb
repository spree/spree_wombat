require 'active_model/serializer'

module Spree
  module Wombat
    class ReturnItemSerializer < ActiveModel::Serializer
      attributes :return_authorization_id, :product_id, :exchange_product_id,
        :reception_status, :acceptance_status, :pre_tax_amount, :included_tax_total,
        :additional_tax_total

      def product_id
        object.inventory_unit.variant.sku
      end

      def exchange_product_id
        object.exchange_variant.try(:sku)
      end

      def return_authorization_id
        object.return_authorization.try(:number)
      end
    end
  end
end
