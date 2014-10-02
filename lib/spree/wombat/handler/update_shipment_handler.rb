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
              state = Spree::State.find_by_abbr(state_name) unless state
              if state
                address_attributes[:state_id] = state.id
              else
                address_attributes[:state_name] = state_name
              end
            end

            shipment_hsh[:address_attributes] = address_attributes
          end


          target_state = shipment_hsh.delete(:status)
          email = shipment_hsh.delete(:email)

          stock_location_name = shipment_hsh.delete(:stock_location)
          stock_location = Spree::StockLocation.find_by_name(stock_location_name) || Spree::StockLocation.find_by_admin_name(stock_location_name)
          return response("Can't find a StockLocation with name #{stock_location_name}!", 500) unless stock_location
          shipment_hsh[:stock_location_id] = stock_location.id

          shipping_method_name = shipment_hsh.delete(:shipping_method)
          shipping_method = Spree::ShippingMethod.find_by_name(shipping_method_name) || Spree::ShippingMethod.find_by_admin_name(shipping_method_name)
          return response("Can't find a ShippingMethod with name #{shipping_method_name}!", 500) unless shipping_method

          shipment_attributes = shipment_hsh.slice *Spree::Shipment.attribute_names
          shipment_attributes["address_attributes"] = address_attributes if address_attributes

          missing_variants = []
          missing_inventory_units = []

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

              inventory_unit_id = shipment.inventory_units.where(variant_id: variant.id).pluck(:id).first
              unless inventory_unit_id
                missing_inventory_units << sku
                next
              end
            end

            # check on items sku and quantity
            shipment_lines = shipment.inventory_units.map do |inventory_unit|
              quantity = inventory_unit.respond_to?(:quantity) ? inventory_unit.quantity : 1
              { sku: inventory_unit.variant.sku, quantity: quantity }
            end

            received_shipping_items = shipping_items.map { |item| {sku: item[:product_id], quantity: item[:quantity].to_i} }

            shipping_items_diff = received_shipping_items.reject do |item|
              # using Array#delete deletes all of the instances of the item, we just want to delete the first
              index_of_item = shipment_lines.index(item)
              index_of_item && shipment_lines.delete_at(index_of_item)
            end

            return response("The received shipment items do not match with the shipment, diff: #{shipping_items_diff}", 500) unless shipping_items_diff.empty?

            return response("Can't find variants with the following skus: #{missing_variants.join(', ')}", 500) unless missing_variants.empty?
            return response("Can't find inventory_units with the following skus: #{missing_inventory_units.join(', ')} in the order.", 500) unless missing_inventory_units.empty?
          end

          # check if a state transition is required, and search for correct event to fire
          transition = nil

          if shipment.state != target_state
            unless transition = shipment.state_transitions.detect { |trans| trans.to == target_state }
              return response("Cannot transition shipment from current state: '#{shipment.state}' to requested state: '#{target_state}', no transition found.", 500)
            end
          end

          #update attributes
          shipment.update(shipment_attributes)

          #fire state transition
          if transition
            shipment.fire_state_event(transition.event)
          end


          shipment.shipping_methods << shipping_method unless shipment.shipping_methods.include? shipping_method
          shipment.refresh_rates
          shipment.save!

          # Ensure Order shipment state and totals are updated.
          # Note: we call update_shipment_state separately from update in case order is not in completed.
          shipment.order.updater.update_shipment_state
          shipment.order.updater.update

          #make sure we set the provided cost, since the order updater is refreshing the shipment rates
          # based on the shipping method.
          shipment.update_columns(cost: shipment_attributes[:cost]) if shipment_attributes[:cost].present?

          return response("Updated shipment #{shipment_number}", 200, Base.wombat_objects_for(shipment))
        end

      end
    end
  end
end
