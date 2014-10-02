module Spree
  module Wombat
    module Handler
      class AddOrderHandler < OrderHandlerBase

        def process
          payload = @payload[:order]
          order_params = OrderHandlerBase.order_params(payload)


          adjustment_attrs = []

          shipping_adjustment = nil
          tax_adjustment = nil

          unless order_params["shipments_attributes"].present?
            # remove possible shipment adjustment here
            order_params["adjustments_attributes"].each do |adjustment|
              adjustment_attrs << adjustment unless adjustment["label"].downcase == "shipping"
              shipping_adjustment = adjustment if adjustment["label"].downcase == "shipping"
            end
          end

          order_params["adjustments_attributes"] = adjustment_attrs if adjustment_attrs.present?
          order = Spree::Core::Importer::Order.import(find_spree_user,order_params)
          order.reload

          number_of_shipments_created = order.shipments.count
          shipping_cost = payload["totals"]["shipping"]
          order.shipments.each do |shipment|
            cost_per_shipment = BigDecimal.new(shipping_cost.to_s) / number_of_shipments_created
            shipment.update_columns(cost: cost_per_shipment)
          end
          order.updater.update_shipment_total
          order.updater.update_payment_state
          order.updater.persist_totals
          response "Order number #{order.number} was added", 200, Base.wombat_objects_for(order.reload)
        end

        private

        def find_spree_user
          Spree.user_class.where(email: @payload[:order][:email]).first_or_create
        end

      end
    end
  end
end
