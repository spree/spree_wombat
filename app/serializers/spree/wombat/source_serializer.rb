require 'active_model/serializer'

module Spree
  module Wombat
    class SourceSerializer < ActiveModel::Serializer
      attributes :name, :cc_type, :last_digits

      def name
        object.name
      end

      def cc_type
        object.cc_type
      end

      def last_digits
        object.last_digits
      end
    end
  end
end
