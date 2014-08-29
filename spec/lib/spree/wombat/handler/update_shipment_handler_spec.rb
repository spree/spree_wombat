require 'spec_helper'

module Spree
  module Wombat
    describe Handler::UpdateShipmentHandler do
      let(:message) {::Hub::Samples::Shipment.request}
      let(:handler) { Handler::UpdateShipmentHandler.new(message.to_json) }

      describe "process" do

        context "with all reference data present" do

          let!(:order) { create(:order, number: message['shipment']['order_id']) }
          let!(:variant) { create(:variant, sku: "SPREE-T-SHIRT")}
          let!(:line_item) { create(:line_item, order: order, variant: variant)}
          let!(:stock_location) { create(:stock_location, name: 'default')}
          let!(:shipping_method) { create(:shipping_method, name: 'UPS Ground (USD)')}
          let!(:country) { create(:country) }
          let!(:state) { create(:state, :country => country, name: 'California', abbr: 'CA') }

          let!(:shipment) { create(:shipment, number: message['shipment']['id'], order: order)}

          before do
            #Spree::Variant.stub(:find_by_sku).and_return(order.variants.first)
            #don't want to trigger a state transition for this example
            message['shipment']['status'] = 'pending'
          end

          it "will return a proper message" do
            responder = handler.process
            expect(responder.summary).to eql "Updated shipment #{shipment.number}"
            expect(responder.code).to eql 200
            expect(order.reload.shipment_state).to eq 'pending'
          end

          context "with mismatching items in shipment" do

            before do
              original_item = message['shipment']['items'].first
              message['shipment']['items'] << original_item
            end

            it "will return an error message with the mismatch diff" do
              responder = handler.process
              expect(responder.summary).to match /The received shipment items do not match with the shipment, diff:/
              expect(responder.code).to eql 500
            end
          end

          context "with multiple of the same items in a shipment" do
            before do
              new_inventory_unit = shipment.inventory_units.last.dup
              new_inventory_unit.save!
              original_item = message['shipment']['items'].first
              message['shipment']['items'] << original_item
            end

            it "will return a proper message" do
              responder = handler.process
              expect(responder.summary).to eql "Updated shipment #{shipment.number}"
              expect(responder.code).to eql 200
            end

          end

          context "including a valid state transition" do
            before do
              message['shipment']['status'] = 'canceled'
            end

            it 'should transition the shipment to the correct state, using the correct event' do
              Spree::Shipment.any_instance.should_receive(:fire_state_event)
                                          .with(:cancel)
                                          .and_call_original

              responder = handler.process
              expect(responder.summary).to eql "Updated shipment #{shipment.number}"
              expect(responder.code).to eql 200

              expect(shipment.reload.state).to eql 'canceled'
            end
          end

          context "including an invalid state transition" do
            before do
              message['shipment']['status'] = 'shipped'
            end

            it 'should NOT transition the shipment to the requested state, and return an error' do

              responder = handler.process
              expect(responder.summary).to eql "Cannot transition shipment from current state: 'pending' to requested state: 'shipped', no transition found."
              expect(responder.code).to eql 500

              expect(shipment.reload.state).to eql 'pending'
            end
          end

          context "finds stock location" do
            context "when a stock location with name equal to stock_location in the message exists" do
              it "find stock location by name" do
                responder = handler.process
                expect(responder.code).to eql 200
                expect(shipment.reload.stock_location).to eql stock_location
              end
            end

            context "when a stock location with admin name equal to stock_location in the message exists" do
              let!(:stock_location) { create(:stock_location, name: 'a stock location name', admin_name: 'default')}

              it "find stock location by admin name" do
                responder = handler.process
                expect(responder.code).to eql 200
                expect(shipment.reload.stock_location).to eql stock_location
              end
            end
          end

          context "finds shipping method" do
            context "when a shipping method with name equal to shipping_method in the message exists" do
              it "find a shipping method by name" do
                responder = handler.process
                expect(responder.code).to eql 200
                expect(shipment.reload.shipping_methods.first).to eql shipping_method
              end
            end

            context "when a shipping method with admin name equal to shipping_method in the message exists" do
              let!(:shipping_method) { create(:shipping_method, name: 'a shipping method name', admin_name: 'UPS Ground (USD)')}

              it "find a shipping method by admin name" do
                responder = handler.process
                expect(responder.code).to eql 200
                expect(shipment.reload.shipping_methods.first).to eql shipping_method
              end
            end
          end
        end
      end
    end
  end
end
