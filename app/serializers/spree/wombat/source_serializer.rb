require 'active_model_serializers'

module Spree
  module Wombat
    class SourceSerializer < ActiveModel::Serializer
      attributes :name, :cc_type, :last_digits, :source_type

      def name
        object.try(:name) || "N/A"
      end

      def cc_type
        object.try(:cc_type) || "N/A"
      end

      def last_digits
        object.try(:last_digits) || "N/A"
      end

      def source_type
        object.class.to_s
      end
    end
  end
end
