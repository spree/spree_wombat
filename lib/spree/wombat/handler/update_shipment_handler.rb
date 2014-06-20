module Spree
  module Wombat
    module Handler
      class UpdateShipmentHandler < Base

        def process

          shipment_hsh = @payload[:shipment]

          order_number = shipment_hsh.delete(:order_id)
          shipment_number = shipment_hsh.delete(:id)

          shipment = Spree::Shipment.find_by_number(shipment_number)
          return response("Can't find shipment #{shipment_number}", 500) unless shipment

          address_attributes = shipment_hsh.delete(:shipping_address)
          if address_attributes
            country_iso = address_attributes.delete(:country)
            country = Spree::Country.find_by_iso(country_iso)
            return response("Can't find a country with iso name #{country_iso}!", 500) unless country_iso
            address_attributes[:country_id] = country.id

            state_name = address_attributes.delete(:state)
            if state_name
              state = Spree::State.find_by_name(state_name)
              return response("Can't find a State with name #{state_name}!", 500) unless state
              address_attributes[:state_id] = state.id
            end

            shipment_hsh[:address_attributes] = address_attributes
          end

          shipment_hsh[:state] = shipment_hsh.delete(:status)
          email = shipment_hsh.delete(:email)

          stock_location_name = shipment_hsh.delete(:stock_location)
          stock_location = Spree::StockLocation.find_by_name(stock_location_name)
          return response("Can't find a StockLocation with name #{stock_location_name}!", 500) unless stock_location
          shipment_hsh[:stock_location_id] = stock_location.id

          shipping_method_name = shipment_hsh.delete(:shipping_method)
          shipping_method = Spree::ShippingMethod.find_by_name(shipping_method_name)
          return response("Can't find a ShippingMethod with name #{shipping_method_name}!", 500) unless shipping_method

          shipment_attributes = shipment_hsh.slice *Spree::Shipment.attribute_names
          shipment_attributes["address_attributes"] = address_attributes


          # build the inventory units
          inventory_units_attributes = []
          missing_variants = []
          missing_line_items = []

          shipping_items = shipment_hsh.delete(:items)
          if shipping_items
            shipping_items.each do |shipping_item|
              # get variant
              sku = shipping_item[:product_id]
              variant = Spree::Variant.find_by_sku(sku)

              unless variant.present?
                missing_variants << sku
                next
              end

              line_item_id = shipment.order.line_items.where(variant_id: variant.id).pluck(:id).first
              unless line_item_id
                missing_line_items << sku
                next
              end
              quantity = shipping_item[:quantity]
              quantity.times do
                inventory_unit = {
                  variant_id: variant.id,
                  order_id: shipment.order.id,
                  line_item_id: line_item_id
                }
                inventory_units_attributes << inventory_unit
              end
            end

            return response("Can't find variants with the following skus: #{missing_variants.join(', ')}", 500) unless missing_variants.empty?
            return response("Can't find line_items with the following skus: #{missing_line_items.join(', ')} in the order.", 500) unless missing_line_items.empty?

            shipment_attributes["inventory_units_attributes"] = inventory_units_attributes
          end
          shipment.update(shipment_attributes)
          shipment.shipping_methods << shipping_method unless shipment.shipping_methods.include? shipping_method
          shipment.refresh_rates
          shipment.save!

          return response("Updated shipment #{shipment_number}")

        end

      end
    end
  end
end
