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
            expect(order.reload.shipment_state).to eq  'partial'
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
                expect(responder.summary).to match "Added shipment #{message["shipment"]["id"]} for order R154085346"
                expect(responder.code).to eql 200
              end
            end
          end

          context "finds stock location" do
            context "when a stock location with name equal to stock_location in the message exists" do
              it "find stock location by name" do
                responder = handler.process
                expect(responder.code).to eql 200
                expect(order.reload.shipments.last.stock_location).to eql stock_location
              end
            end

            context "when a stock location with admin name equal to stock_location in the message exists" do
              let!(:stock_location) { create(:stock_location, name: 'a stock location name', admin_name: 'default')}

              it "find stock location by admin name" do
                responder = handler.process
                expect(responder.code).to eql 200
                expect(order.reload.shipments.last.stock_location).to eql stock_location
              end
            end
          end

          context "finds shipping method" do
            context "when a shipping method with name equal to shipping_method in the message exists" do
              it "find a shipping method by name" do
                responder = handler.process
                expect(responder.code).to eql 200
                expect(order.reload.shipments.last.shipping_method).to eql shipping_method
              end
            end

            context "when a shipping method with admin name equal to shipping_method in the message exists" do
              let!(:shipping_method) { create(:shipping_method, name: 'a shipping method name', admin_name: 'UPS Ground (USD)')}

              it "find a shipping method by admin name" do
                responder = handler.process
                expect(responder.code).to eql 200
                expect(order.reload.shipments.last.shipping_method).to eql shipping_method
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
