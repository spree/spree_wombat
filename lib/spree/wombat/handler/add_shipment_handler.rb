module Spree
  module Wombat
    module Handler
      class AddShipmentHandler < Base

        def process

          shipment = @payload[:shipment]

          order_number = shipment.delete(:order_id)
          order = Spree::Order.find_by_number(order_number)
          return response("Can't find order #{order_number} associated with this shipment", 500) unless order

          shipment[:order_id] = order.id

          external_id = shipment.delete(:id)

          existing_shipment = Spree::Shipment.find_by_number(external_id)
          return response("Already have a shipment for order #{order_number} associated with shipment number #{external_id}", 200) if existing_shipment

          address_attributes = shipment.delete(:shipping_address)
          country_iso = address_attributes.delete(:country)
          country = Spree::Country.find_by_iso(country_iso)
          return response("Can't find a country with iso name #{country_iso}!", 500) unless country_iso
          address_attributes[:country_id] = country.id

          state_name = address_attributes.delete(:state)
          if state_name
            state = Spree::State.find_by_name(state_name)
            state = Spree::State.find_by_abbr(state_name) unless state
            if state
              address_attributes[:state_id] = state.id
            else
              address_attributes[:state_name] = state_name
            end
          end

          shipment[:state] = shipment.delete(:status)
          email = shipment.delete(:email)

          stock_location_name = shipment.delete(:stock_location)
          stock_location = Spree::StockLocation.find_by_name(stock_location_name) || Spree::StockLocation.find_by_admin_name(stock_location_name)
          return response("Can't find a StockLocation with name #{stock_location_name}!", 500) unless stock_location
          shipment[:stock_location_id] = stock_location.id

          shipping_method_name = shipment.delete(:shipping_method)
          shipping_method = Spree::ShippingMethod.find_by_name(shipping_method_name) || Spree::ShippingMethod.find_by_admin_name(shipping_method_name)
          return response("Can't find a ShippingMethod with name #{shipping_method_name}!", 500) unless shipping_method

          # build the inventory units
          inventory_units_attributes = []
          missing_variants = []
          missing_line_items = []

          shipping_items = shipment.delete(:items)

          shipping_items.each do |shipping_item|
            # get variant
            sku = shipping_item[:product_id]
            variant = Spree::Variant.find_by_sku(sku)

            unless variant.present?
              missing_variants << sku
              next
            end

            line_item_id = order.line_items.where(variant_id: variant.id).pluck(:id).first
            unless line_item_id
              missing_line_items << sku
              next
            end
            quantity = shipping_item[:quantity]
            quantity.times do
              inventory_unit = {
                variant_id: variant.id,
                order_id: order.id,
                line_item_id: line_item_id
              }
              inventory_units_attributes << inventory_unit
            end
          end

          return response("Can't find variants with the following skus: #{missing_variants.join(', ')}", 500) unless missing_variants.empty?
          return response("Can't find line_items with the following skus: #{missing_line_items.join(', ')} in the order.", 500) unless missing_line_items.empty?

          shipment_attributes = shipment.slice *Spree::Shipment.attribute_names
          shipment_attributes["inventory_units_attributes"] = inventory_units_attributes
          shipment_attributes["address_attributes"] = address_attributes
          shipment_attributes["number"] = external_id
          shipment_attributes["state"] ||= 'pending'
          shipment = Spree::Shipment.create!(shipment_attributes)
          shipment.shipping_methods << shipping_method
          shipment.refresh_rates
          shipment.save!

          # Ensure Order shipment state and totals are updated.
          # Note: we call update_shipment_state separately from update in case order is not in completed.
          order.updater.update_shipment_state
          order.updater.update

          #make sure we set the provided cost, since the order updater is refreshing the shipment rates
          # based on the shipping method.
          shipment.update_columns(cost: shipment_attributes[:cost]) if shipment_attributes[:cost].present?

          shipments_payload = []
          shipment.order.reload.shipments.each do |shipment|
            shipments_payload << ShipmentSerializer.new(shipment.reload, root: false).serializable_hash
          end
          return response("Added shipment #{shipment.number} for order #{order.number}", 200, Base.wombat_objects_for(shipment))
        end

      end
    end
  end
end
