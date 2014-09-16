require 'spec_helper'

shared_examples "updates inventory level and responds with proper message" do
  let!(:stock_item) do
    item = variant.stock_items.first
    item.stock_location = stock_location
    item.save
    item
  end

  it "will set the inventory to the supplied amount" do
    expect{handler.process}.to change{stock_item.reload.count_on_hand}.from(0).to(93)
  end

  it "returns a Hub::Responder with a proper message" do
    responder = handler.process
    expect(responder.summary).to eql "Set inventory for SPREE-T-SHIRT at us_warehouse from 0 to 93"
    expect(responder.code).to eql 200
  end
end

module Spree
  module Wombat
    describe Handler::SetInventoryHandler do
      let(:message) {::Hub::Samples::Inventory.request}
      let(:handler) { Handler::SetInventoryHandler.new(message.to_json) }

      describe "process" do

        context "with stock item present" do
          let(:variant) { create(:variant, :sku => 'SPREE-T-SHIRT') }

          context "and the stock location name is equal to location in the message" do
            let!(:stock_location) { create(:stock_location, name: 'us_warehouse')}

            include_examples "updates inventory level and responds with proper message"
          end

          context "and the stock location admin name is equal to location in the message" do
            let!(:stock_location) { create(:stock_location, name: 'a stock location name', admin_name: 'us_warehouse')}

            include_examples "updates inventory level and responds with proper message"
          end
        end

        context "with stock item not present" do
          it "returns a Hub::Responder with 500 status" do
            responder = handler.process
            expect(responder.summary).to eql "Stock location with name us_warehouse was not found"
            expect(responder.code).to eql 500
          end
        end

      end

    end
  end
end
