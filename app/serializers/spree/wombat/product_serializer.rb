require 'active_model/serializer'

module Spree
  module Wombat
    class ProductSerializer < ActiveModel::Serializer

      attributes :id, :name, :sku, :description, :price, :cost_price,
                 :available_on, :permalink, :meta_description, :meta_keywords,
                 :shipping_category, :taxons, :options

      has_many :images, serializer: Spree::Wombat::ImageSerializer
      has_many :variants_including_master, serializer: Spree::Wombat::VariantSerializer, root: "variants"

      def id
        object.sku
      end

      def price
        object.price.to_f
      end

      def cost_price
        object.cost_price.to_f
      end

      def available_on
        object.available_on.iso8601
      end

      def shipping_category
        object.shipping_category.name
      end

      def taxons
        object.taxons.collect {|t| t.root.self_and_descendants.collect(&:name)}
      end

      def options
        object.option_types.pluck(:name)
      end

    end
  end
end
