require 'spec_helper'

module Spree
  module Wombat
    describe Handler::AddOrderHandler do
      let!(:country) { create(:country) }
      let!(:state) { country.states.first || create(:state, :country => country) }

      let!(:user) do
        user = Spree.user_class.new(:email => "spree@example.com")
        user.generate_spree_api_key!
        user
      end

      let!(:variant) { create(:variant, :id => 73) }
      let!(:payment_method) { create(:credit_card_payment_method, name: 'bogus') }

      context "#process" do
        context "with shopify order data" do
          let!(:message) do
            msg = ::Hub::Samples::Order.request
            msg["order"] = {
              "id"=> "schoftech_1018",
              "shopify_id"=> "342660281",
              "source"=> "schoftech.myshopify.com",
              "channel"=> "schoftech.myshopify.com",
              "status"=> "complete",
              "email"=> "sameer@spreecommerce.com",
              "currency"=> "USD",
              "placed_on"=> "2014-10-01T13=>38=>28Z",
              "totals"=> {
                "item"=> 38,
                "tax"=> 0,
                "shipping"=> 10,
                "payment"=> 49.9,
                "order"=> 49.9,
                "adjustment"=> 11.9
              },
              "line_items"=> [
                {
                  "id"=> 235,
                  "product_id"=> "SPR-00001-Variant",
                  "name"=> "Spree Baseball Jersey",
                  "quantity"=> 2,
                  "price"=> 19
                }
              ],
              "adjustments"=> [
                {
                  "name"=> "discount",
                  "value"=> 11.9
                },
                {
                  "name"=> "tax",
                  "value"=> 0
                },
                {
                  "name"=> "shipping",
                  "value"=> 10
                }
              ],
              "shipping_address"=> {
                "firstname"=> "Sameer",
                "lastname"=> "Gulati",
                "address1"=> "3627 Ordway Street NW",
                "address2"=> "",
                "zipcode"=> "20814",
                "city"=> "Bethesda",
                "state"=> "MD",
                "country"=> "US",
                "phone"=> "4084552962"
              },
              "billing_address"=> {
                "firstname"=> "Sameer",
                "lastname"=> "Gulati",
                "address1"=> "3627 Ordway Street NW",
                "address2"=> "",
                "zipcode"=> "20814",
                "city"=> "Bethesda",
                "state"=> "MD",
                "country"=> "US",
                "phone"=> "4084552962"
              },
              "payments"=> [
                {
                  "id"=> 45,
                  "number"=> "AKJSKJHD",
                  "status"=> "completed",
                  "amount"=> 49.9,
                  "payment_method"=> "bogus"
                }
              ],
              "updated_at"=> "2014-10-01T13=>40=>55Z",
              "token"=> "36a7b988b2e068e5",
              "shipping_instructions"=> nil
            }
            msg
          end
          let(:handler) { Handler::AddOrderHandler.new(message.to_json) }

          let(:line_item) { message['order']['line_items'].first }

          before { create(:variant, sku: line_item['product_id']) }

          it "imports a new order in the storefront" do
            expect{handler.process}.to change{Spree::Order.count}.by(1)
          end

          it "sets number from order payload id" do
            handler.process
            expect(Order.last.number).to eq message['order']['id']
          end

          it "creates line items properly" do
            handler.process
            expect(LineItem.last.variant.sku).to eq line_item['product_id']
          end

          it "returns a Hub::Responder" do
            responder = handler.process
            expect(responder.class.name).to eql "Spree::Wombat::Responder"
            expect(responder.request_id).to eql message["request_id"]
            expect(responder.summary).to match /Order number schoftech_1018 was added/
          end

          it "adding the payment" do
            expect{handler.process}.to change{Spree::Payment.count}.by(1)
          end

          it "generating proposed shipments" do
            expect{handler.process}.to change{Spree::Shipment.count}.by(1)
          end

          context "payment" do
            before do
              handler.process
              order = Spree::Order.find_by_number("schoftech_1018")
              @payment = order.payments.first
            end

            it "amount is set correctly" do
              expect(@payment.amount).to eql 49.9
            end

          end

          context "shipments" do
            before do
              handler.process
              order = Spree::Order.find_by_number("schoftech_1018")
              @shipment = order.shipments.first
            end

            it "cost is set correctly" do
              expect(@shipment.cost).to eql 10
            end
          end

          context "adjustments" do
            before do
              handler.process
              @order = Spree::Order.find_by_number("schoftech_1018")
            end

            it "shipment total" do
              expect(@order.shipment_total).to eql 10.0
            end
          end

        end
      end
    end
  end
end
