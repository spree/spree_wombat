module Spree
  module Wombat
    module Handler
      class UpdateShipmentHandler < ShipmentHandlerBase

        def process

          shipment_number = @shipment_payload.delete(:id)
          shipment = Spree::Shipment.find_by_number(shipment_number)
          return response("Can't find shipment #{shipment_number}", 500) unless shipment

          order = shipment.order

          address_attributes = prepare_address_attributes
          @shipment_payload[:address_attributes] = address_attributes

          shipping_method = fetch_shipping_method
          return response("Can't find a ShippingMethod with name #{shipping_method_name}!", 500) unless shipping_method

          inventory_units_hash = prepare_inventory_units(order)
          missing_variants = inventory_units_hash[:missing_variants]
          missing_line_items = inventory_units_hash[:missing_line_items]
          inventory_units_attributes = inventory_units_hash[:inventory_units_attributes]

          return response("Can't find variants with the following skus: #{missing_variants.join(', ')}", 500) unless missing_variants.empty?
          return response("Can't find line_items with the following skus: #{missing_line_items.join(', ')} in the order.", 500) unless missing_line_items.empty?

          @shipment_payload[:inventory_units_attributes] = inventory_units_attributes

          @shipment_payload[:state] = @shipment_payload.delete(:status)
          shipment.update_attributes(@shipment_payload)
          shipment.shipping_method = shipping_method
          shipment.save!
          shipment.update!(order)

          return response("Updated shipment #{shipment.number} for order #{order.number}")

        end

      end
    end
  end
end
