require 'active_model_serializers'

module Spree
  module Wombat
    class RefundSerializer < ActiveModel::Serializer
      attributes :reason, :amount, :description
      has_one :payment, serializer: Spree::Wombat::PaymentSerializer

      def reason
        object.reason.try(:name)
      end
    end
  end
end
