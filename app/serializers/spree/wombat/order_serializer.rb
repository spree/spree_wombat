require 'active_model_serializers'

module Spree
  module Wombat
    class OrderSerializer < ActiveModel::Serializer

      attributes :id, :status, :channel, :email, :currency, :placed_on, :updated_at, :totals,
        :adjustments, :guest_token, :shipping_instructions

      has_many :line_items,  serializer: Spree::Wombat::LineItemSerializer
      has_many :payments, serializer: Spree::Wombat::PaymentSerializer

      has_one :shipping_address, serializer: Spree::Wombat::AddressSerializer
      has_one :billing_address, serializer: Spree::Wombat::AddressSerializer

      def id
        object.number
      end

      def shipping_instructions
        object.special_instructions
      end

      def status
        object.state
      end

      def channel
        object.channel || 'spree'
      end

      def updated_at
        object.updated_at.getutc.try(:iso8601)
      end

      def placed_on
        if object.completed_at?
          object.completed_at.getutc.try(:iso8601)
        else
          ''
        end
      end

      def totals
        {
          item: object.item_total.to_f,
          adjustment: adjustment_total,
          tax: tax_total,
          shipping: shipping_total,
          payment: object.payments.completed.sum(:amount).to_f,
          order: object.total.to_f
        }
      end

      def adjustments
        [
          { name: 'discount', value: object.promo_total.to_f },
          { name: 'tax', value: tax_total },
          { name: 'shipping', value: shipping_total }
        ]
      end

      private

        def adjustment_total
          object.adjustment_total.to_f
        end

        def shipping_total
          object.shipment_total.to_f
        end

        def tax_total
          tax = 0.0
          tax_rate_taxes = (object.included_tax_total + object.additional_tax_total).to_f
          manual_import_adjustment_tax_adjustments = object.adjustments.select{|adjustment| adjustment.label.downcase == "tax" && adjustment.source_id == nil && adjustment.source_type == nil}
          if(tax_rate_taxes == 0.0 && manual_import_adjustment_tax_adjustments.present?)
            tax = manual_import_adjustment_tax_adjustments.sum(&:amount).to_f
          else
            tax = tax_rate_taxes
          end
          tax
        end

    end
  end
end
