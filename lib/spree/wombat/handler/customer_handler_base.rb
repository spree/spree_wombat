module Spree
  module Wombat
    module Handler
      class CustomerHandlerBase < Base

        def prepare_address(firstname, lastname, address_attributes)

          address_attributes['country'] = {
            'iso' => address_attributes['country'].upcase }

          if address_attributes['state'].length == 2
            address_attributes['state'] = {
              'abbr' => address_attributes['state'].upcase }
          else
            address_attributes['state'] = {
              'name' => address_attributes['state'].capitalize }
          end

          address_attributes[:firstname] = firstname
          address_attributes[:lastname] = lastname

          address_attributes
        end
        
        def ensure_country_id_from_params(address)
          return if address.nil? or address[:country_id].present? or address[:country].nil?

          begin
            search = {}
            if name = address[:country]['name']
              search[:name] = name
            elsif iso_name = address[:country]['iso_name']
              search[:iso_name] = iso_name.upcase
            elsif iso = address[:country]['iso']
              search[:iso] = iso.upcase
            elsif iso3 = address[:country]['iso3']
              search[:iso3] = iso3.upcase
            end

            address.delete(:country)
            address[:country_id] = Spree::Country.where(search).first!.id

          rescue Exception => e
            raise "Ensure order have well define address country: #{e.message} #{search}"
          end
        end

        def ensure_state_id_from_params(address)
          return if address.nil? or address[:state_id].present? or address[:state].nil?

          begin
            search = {}
            if name = address[:state]['name']
              search[:name] = name
            elsif abbr = address[:state]['abbr']
              search[:abbr] = abbr.upcase
            end

            address.delete(:state)
            search[:country_id] = address[:country_id]

            if state = Spree::State.where(search).first
              address[:state_id] = state.id
            else
              address[:state_name] = search[:name] || search[:abbr]
            end
          rescue Exception => e
            raise "Ensure order have well define address state: #{e.message} #{search}"
          end
        end        

      end
    end
  end
end
