require "spec_helper"

module Spree
  module Wombat
    describe ShipmentSerializer do

      let(:shipment) { create(:shipment, order: create(:order_with_line_items)) }
      let(:serialized_shipment) { JSON.parse (ShipmentSerializer.new(shipment, root: false).to_json) }

      it "serializes the number as id" do
        expect(serialized_shipment["id"]).to eql shipment.number
      end

      it "serializes the order number as order_id" do
        expect(serialized_shipment["order_id"]).to eql shipment.order.number
      end

      it "serializes the order email as email" do
        expect(serialized_shipment["email"]).to eql shipment.order.email
      end

      it "serializes the cost as float" do
        expect(serialized_shipment["cost"].class).to eql Float
      end

      it "serializes the state at status" do
        expect(serialized_shipment["status"]).to eql shipment.state
      end

      it "serializes the stock_location.name as stock_location" do
        expect(shipment.stock_location.name).to_not eql nil
        expect(serialized_shipment["stock_location"]).to eql shipment.stock_location.name
      end

      it "serializes the shipping_method.name as shipping_method" do
        expect(shipment.shipping_method.name).to_not eql nil
        expect(serialized_shipment["shipping_method"]).to eql shipment.shipping_method.name
      end

      it "serializes the updated_at in ISO format" do
        expect(serialized_shipment["updated_at"]).to match /\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/
      end

      it "serializes the shipped_at in ISO format" do
        shipment.stub(:shipped_at).and_return Time.now.utc
        expect(serialized_shipment["shipped_at"]).to match /\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/
      end

      it "serializes the address as shipping_address" do
        expect(serialized_shipment["shipping_address"]).to_not be_nil
        address = JSON.parse(AddressSerializer.new(shipment.address, root: false).to_json)
        expect(serialized_shipment["shipping_address"]).to eql address
      end

      it "serializes the line_items as items" do
        expect(shipment.line_items).to_not be_nil
        expect(shipment.line_items).to_not be_empty
        expect(serialized_shipment["items"]).to_not be_nil
        expect(serialized_shipment["items"]).to_not be_empty
        line_items = JSON.parse(
          ActiveModel::ArraySerializer.new(
            shipment.line_items,
            each_serializer: Spree::Wombat::LineItemSerializer,
            root: false
          ).to_json
        )
        expect(serialized_shipment["items"]).to eql line_items
      end
    end
  end
end
