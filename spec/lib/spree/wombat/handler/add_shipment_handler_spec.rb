require 'spec_helper'

module Spree
  module Wombat
    describe Handler::AddShipmentHandler do
      let(:message) {::Hub::Samples::Shipment.request}
      let(:handler) { Handler::AddShipmentHandler.new(message.to_json) }

      describe "process" do

        context "with all reference data present" do

          let!(:order) do
            order = create(:completed_order_with_totals, number: message["shipment"]["order_id"] )
            2.times do
              create(:line_item, order: order)
            end
            order.update!
            order.reload
          end

          let!(:shipping_method) { create(:shipping_method, name: 'UPS Ground (USD)')}
          let!(:country) { Spree::Country.first }
          let!(:state) { create(:state, :country => country, name: "California", abbr: "CA") }

          before do
            Spree::Variant.stub(:find_by_sku).and_return(order.variants.first)
          end

          it "will add a new shipment to the order" do
            expect{handler.process}.to change{order.reload.shipments.count}.by(1)
          end

          it "will return a proper message" do
            responder = handler.process
            expect(responder.summary).to match /Added shipment H.{11} for order R154085346/
            expect(responder.code).to eql 200
          end

        end

      end

    end
  end
end
