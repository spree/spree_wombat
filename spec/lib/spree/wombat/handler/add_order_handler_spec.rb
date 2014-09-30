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
      let!(:payment_method) { create(:credit_card_payment_method) }

      context "#process" do
        context "with sane order data" do
          let!(:message) { ::Hub::Samples::Order.request }
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
            expect(responder.summary).to match /Order number R.{9} was added/
          end
        end

        context "with custom non existing spree attributes on line_items" do
          let!(:message) { ::Hub::Samples::Order.request }
          let(:handler) { Handler::AddOrderHandler.new(message.to_json) }

          let(:line_item) do
            li = message['order']['line_items'].first
            li[:shopify_id] = 1234
            li
          end

          before { create(:variant, sku: line_item['product_id']) }

          it "importing the order will ignore the non existing attributes" do
            handler.process
            expect(LineItem.last.variant.sku).to eq line_item['product_id']
          end

        end

        context "with abbreviated state name" do
          let!(:message) { ::Hub::Samples::Order.request }
          let(:handler) {
            message['order']['billing_address']['state'] = 'CA'
            message['order']['shipping_address']['state'] = 'CA'
            Handler::AddOrderHandler.new(message.to_json)
          }

          let(:line_item) { message['order']['line_items'].first }

          before { create(:variant, sku: line_item['product_id']) }

          it "imports a new order in the storefront" do
            expect{handler.process}.to change{Spree::Order.count}.by(1)
          end
        end
      end
    end
  end
end
