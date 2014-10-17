require 'active_model/serializer'

module Spree
  module Wombat
    module Jirafe

      class LineItemSerializer < ActiveModel::Serializer
        attributes :id, :created_at, :updated_at, :product_id, :name,
         :quantity, :price, :variant

        def created_at
          object.created_at.getutc.try(:iso8601)
        end

        def updated_at
          object.updated_at.getutc.try(:iso8601)
        end

        def variant
          Spree::Wombat::Jirafe::VariantSerializer.new(object.variant, root:false)
        end

        def product_id
          object.variant.sku
        end

        def price
          object.price.to_f
        end
      end

    end
  end
end
