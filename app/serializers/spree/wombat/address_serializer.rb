require 'active_model/serializer'

module Spree
  module Wombat
    class AddressSerializer < ActiveModel::Serializer
      attributes :firstname, :lastname, :address1, :address2, :zipcode, :city,
                 :state, :country, :phone

      def country
        object.country.iso
      end

      def state
        if object.state
          object.state.name
        else
          nil
        end
      end

    end
  end
end
