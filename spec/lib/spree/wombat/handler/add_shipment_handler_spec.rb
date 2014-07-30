require 'spec_helper'

module Spree
  module Wombat
    describe Handler::AddShipmentHandler do
      let(:message) {::Hub::Samples::Shipment.request}
      let(:handler) { Handler::AddShipmentHandler.new(message.to_json) }

      describe "process" do

        context "with all reference data present" do

          let!(:order) { create(:order_with_line_items, number: message["shipment"]["order_id"]) }
          let!(:stock_location) { create(:stock_location, name: 'default')}
          let!(:shipping_method) { create(:shipping_method, name: 'UPS Ground (USD)')}
          let!(:country) { create(:country) }
          let!(:state) { create(:state, :country => country, name: "California", abbr: "CA") }

          before do
            Spree::Variant.stub(:find_by_sku).and_return(order.variants.first)
          end

          it "will add a new shipment to the order" do
            expect{handler.process}.to change{order.reload.shipments.count}.by(1)
          end

          it "will return a proper message" do
            responder = handler.process
            external_id = message["shipment"]["id"]
            expect(responder.summary).to match /Added shipment #{external_id} for order R154085346/
            expect(responder.code).to eql 200
          end

          it "will set the shipment id as the shipment number" do
            responder = handler.process
            external_id = message["shipment"]["id"]
            expect(Spree::Shipment.find_by_number(external_id)).to_not be_nil
          end

          context "attribute filtering" do
            context "with non existing attribute on shipment" do

              before do
                shipment = message["shipment"]
                shipment["note_value"] = "This is not used here"
                message["shipment"] = shipment
              end

              it "will not blow up" do
                responder = handler.process
                expect(responder.summary).to match /Added shipment H.{11} for order R154085346/
                expect(responder.code).to eql 200
              end
            end
          end

          context "finds state" do
            context "by abbr" do

              before do
                shipping_address = message["shipment"]["shipping_address"]
                shipping_address["state"] = "CA"
                message["shipment"]["shipping_address"] = shipping_address
              end

              it "find a state by abbr" do
                responder = handler.process
                expect(responder.code).to eql 200
                expect(order.reload.shipments.last.address.state).to eql state
              end

            end

          end

        end

      end

    end
  end
end
