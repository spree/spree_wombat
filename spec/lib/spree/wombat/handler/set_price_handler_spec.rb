require 'spec_helper'

module Spree
  module Wombat
    describe Handler::SetPriceHandler do
      let(:message) {::Hub::Samples::Price.request}
      let(:handler) { Handler::SetPriceHandler.new(message.to_json) }

      describe "process" do
        context "with stock item present" do
          let!(:variant) { create(:variant, :sku => 'SPREE-T-SHIRT', price: 12.0, cost_price: 5.0) }

          context "and the stock location name is equal to location in the message" do
            it "will set the price to the supplied amount" do
              expect{handler.process}.to change{variant.reload.price.to_f}.from(12.0).to(12.95)
            end

            it "will set the cost_price to the supplied amount" do
              expect{handler.process}.to change{variant.reload.cost_price.to_f}.from(5.0).to(6.25)
            end

            it "returns a Hub::Responder with a proper message" do
              responder = handler.process
              expect(responder.summary).to eql "Set price for SPREE-T-SHIRT from 12.0 USD to 12.95 USD"
              expect(responder.code).to eql 200
            end
          end
        end

        context "with variant not present" do
          it "returns a Hub::Responder with 500 status" do
            responder = handler.process
            expect(responder.summary).to eql "Product with SKU SPREE-T-SHIRT was not found"
            expect(responder.code).to eql 500
          end
        end
      end
    end
  end
end
