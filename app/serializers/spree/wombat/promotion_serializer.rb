require 'active_model_serializers'

module Spree
  module Wombat
    class PromotionSerializer < ActiveModel::Serializer
      attributes :name, :code, :category_name, :category_code

      def category_name
        object.promotion_category.try(:name)
      end

      def category_code
        object.promotion_category.try(:code)
      end
    end
  end
end
