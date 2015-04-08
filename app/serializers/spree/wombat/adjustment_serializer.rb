require 'active_model_serializers'

module Spree
  module Wombat
    class AdjustmentSerializer < ActiveModel::Serializer
      attributes :name, :value

      def name
        object.label
      end

      def value
        object.amount.to_f
      end

    end
  end
end
