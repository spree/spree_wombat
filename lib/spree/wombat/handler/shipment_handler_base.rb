module Spree
  module Wombat
    module Handler
      class ShipmentHandlerBase < Base

        attr_accessor :shipment_payload

        def initialize(message)
          super(message)
          @shipment_payload = @payload[:shipment]
          @shipment_payload.delete(:email)
          @shipment_payload.delete(:stock_location)
        end

        def fetch_order(order_number)
          Spree::Order.find_by_number(order_number)
        end

        def prepare_address_attributes
          attrs = @shipment_payload.delete(:shipping_address)
          country_iso = attrs.delete(:country)
          country = Spree::Country.find_by_iso(country_iso)
          raise Exception.new("Can't find country with ISO #{country_iso}") unless country
          attrs[:country_id] = country.id

          state_name = attrs.delete(:state)
          if state_name
            state = Spree::State.find_by_name(state_name)
            state = Spree::State.find_by_abbr(state_name) unless state
            raise Exception.new("Can't find state with name or abbr with: #{state_name}") unless state
            attrs[:state_id] = state.id
            attrs[:state_name] = state.name
          end
          attrs
        end

        def prepare_inventory_units(order)
          # build the inventory units
          inventory_units_attributes = []
          missing_variants = []
          missing_line_items = []

          shipping_items = @shipment_payload.delete(:items)

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
                order_id: order.id
              }
              inventory_units_attributes << inventory_unit
            end
          end
          {
            missing_variants: missing_variants,
            missing_line_items: missing_line_items,
            inventory_units_attributes: inventory_units_attributes
          }
        end

        def fetch_shipping_method
          shipping_method_name = @shipment_payload.delete(:shipping_method)
          Spree::ShippingMethod.find_by_name(shipping_method_name)
        end

      end
    end
  end
end
