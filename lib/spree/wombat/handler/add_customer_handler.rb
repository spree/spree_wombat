module Spree
  module Wombat
    module Handler
      class AddCustomerHandler < Base

        def process
          email = @payload["customer"]["email"]
          if Spree.user_class.where(email: email).count > 0
            return response "Customer with email '#{email}' already exists!", 500
          end

          user = Spree.user_class.new(email: email)
          user.save(validation: false)

          firstname = payload["customer"]["firstname"]
          lastname = payload["customer"]["lastname"]

          begin
            user.ship_address = prepare_address(firstname, lastname, @payload["customer"]["shipping_address"])
            user.bill_address = prepare_address(firstname, lastname, @payload["customer"]["billing_address"])
          rescue Exception => exception
            return response(exception.message, 500)
          end

          user.save
          response "Added new customer with #{email} and ID: #{user.id}"
        end

        private

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

          Spree::Address.create!(address_attributes)
        end

      end
    end
  end
end
