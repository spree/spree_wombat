require 'spec_helper'

module Spree
  module Wombat
    describe Handler::UpdateOrderHandler do

      context "#process" do

        let!(:message) { ::Hub::Samples::Order.request }
        let(:handler) { Handler::UpdateOrderHandler.new(message.to_json) }

        context "for existing order" do
          let!(:message) { ::Hub::Samples::Order.request }
          let!(:order) { create(:order_with_line_items, number: message["order"]["id"])}

          it "will update the order" do
            email = order.email
            state = order.state

            responder = handler.process
            expect(responder.summary).to  match /Updated Order with number R.{9}/
            expect(responder.code).to eql 200

            expect(order.reload.email).to eql message["order"]["email"]
            expect(order.reload.state).to eql message["order"]["status"]
          end

        end

        context "with no order present" do

          it "returns a Wombat::Responder with 500 status" do
            responder = handler.process
            expect(responder.summary).to match /Order with number R.{9} was not found/
            expect(responder.code).to eql 500
          end

        end
      end

    end
  end
end
