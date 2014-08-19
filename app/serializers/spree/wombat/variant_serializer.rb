require 'active_model/serializer'

module Spree
  module Wombat
    class VariantSerializer < ActiveModel::Serializer

      attributes :sku, :price, :cost_price, :options, :weight, :height, :width, :depth
      has_many :images, serializer: Spree::Wombat::ImageSerializer

      def price
        object.price.to_f
      end

      def cost_price
        object.cost_price.to_f
      end

      def options
        object.option_values.each_with_object({}) {|ov,h| h[ov.option_type.presentation]= ov.presentation}
      end

    end
  end
end
