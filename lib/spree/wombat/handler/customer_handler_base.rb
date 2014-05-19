module Spree
  module Wombat
    module Handler
      class CustomerHandlerBase < Base

        def prepare_address(firstname, lastname, address_attributes)

          country_iso = address_attributes.delete(:country)
          country = Spree::Country.find_by_iso(country_iso)
          raise Exception.new("Can't find a country with iso name #{country_iso}!") unless country_iso
          address_attributes[:country_id] = country.id

          state_name = address_attributes.delete(:state)
          if state_name
            state = Spree::State.find_by_name(state_name)
            raise Exception.new("Can't find a State with name #{state_name}!") unless state
            address_attributes[:state_id] = state.id
          end

          address_attributes[:firstname] = firstname
          address_attributes[:lastname] = lastname

          address_attributes
        end

      end
    end
  end
end
