require 'spec_helper'

module Spree
  module Wombat
    describe Handler::UpdateShipmentHandler do
      let(:message) {::Hub::Samples::Shipment.request}
      let(:handler) { Handler::UpdateShipmentHandler.new(message.to_json) }

      describe "process" do

        context "with all reference data present" do

          let!(:order) { create(:order_with_line_items, number: message['shipment']['order_id']) }
          let!(:stock_location) { create(:stock_location, name: 'default')}
          let!(:shipping_method) { create(:shipping_method, name: 'UPS Ground (USD)')}
          let!(:country) { create(:country) }
          let!(:state) { create(:state, :country => country, name: 'California', abbr: 'CA') }

          let!(:shipment) { create(:shipment, number: message['shipment']['id'], order: order)}

          before do
            Spree::Variant.stub(:find_by_sku).and_return(order.variants.first)
          end

          it "will return a proper message" do
            responder = handler.process
            expect(responder.summary).to eql "Updated shipment #{shipment.number}"
            expect(responder.code).to eql 200
          end

        end

      end

    end
  end
end
