require 'active_model_serializers'

module Spree
  module Wombat
    class ProductSerializer < ActiveModel::Serializer

      attributes :id, :name, :sku, :description, :price, :cost_price,
                 :available_on, :permalink, :meta_description, :meta_keywords,
                 :shipping_category, :taxons, :weight, :height, :width,
                 :depth, :variants

      def attributes
        super.tap do |hash|
          hash.update(options: options_text)
        end
      end

      has_many :images, serializer: Spree::Wombat::ImageSerializer

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
        object.available_on.try(:iso8601)
      end

      def permalink
        object.slug
      end

      def shipping_category
        object.shipping_category.name
      end

      def taxons
        object.taxons.collect {|t| t.self_and_ancestors.collect(&:name)}
      end

      def options_text
        object.option_types.pluck(:name)
      end

      def variants
        if object.variants.empty?
          [Spree::Wombat::VariantSerializer.new(object.master, root:false)]
        else
          ActiveModel::ArraySerializer.new(
            object.variants,
            each_serializer: Spree::Wombat::VariantSerializer,
            root: false
          )
        end
      end
    end
  end
end
