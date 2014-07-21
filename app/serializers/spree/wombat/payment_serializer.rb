require 'active_model/serializer'

module Spree
  module Wombat
    class PaymentSerializer < ActiveModel::Serializer
      attributes :number, :status, :amount, :payment_method

      has_one :source, serializer: Spree::Wombat::SourceSerializer

      def number
        object.identifier
      end

      def payment_method
        object.payment_method.name
      end

      def status
        object.state
      end

      def amount
        object.amount.to_f
      end
    end
  end
end
