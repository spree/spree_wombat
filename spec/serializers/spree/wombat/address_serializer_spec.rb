require "spec_helper"

module Spree
  module Wombat
    describe AddressSerializer do

      let(:address) { create(:address) }
      let(:serialized_address) { AddressSerializer.new(address, root: false).to_json }

      it "serializes the country iso" do
        expect(JSON.parse(serialized_address)["country"]).to eql address.country.iso
      end

      it "serializes the state name" do
        expect(JSON.parse(serialized_address)["state"]).to eql address.state.name
      end

    end
  end
end
