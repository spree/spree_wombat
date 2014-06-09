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

          it "imports a new order in the storefront" do
            expect{handler.process}.to change{Spree::Order.count}.by(1)
          end

          it "sets number from order payload id" do
            handler.process
            expect(Order.last.number).to eq message['order']['id']
          end

          it "returns a Hub::Responder" do
            responder = handler.process
            expect(responder.class.name).to eql "Spree::Wombat::Responder"
            expect(responder.request_id).to eql message["request_id"]
            expect(responder.summary).to match /Order number R.{9} was added/
          end
        end
      end
    end
  end
end
