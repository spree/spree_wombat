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
        end

      end

    end
  end
end
