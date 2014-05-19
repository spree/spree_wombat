require 'spec_helper'

module Spree
  module Wombat
    describe Handler::UpdateCustomerHandler do

      let(:message) { ::Hub::Samples::Customer.request }
      let(:handler) { Handler::UpdateCustomerHandler.new(message.to_json) }

      let!(:country) { create(:country) }
      let!(:state) { create(:state, :country => country, name: "California", abbr: "CA") }

      context "process" do

        context "sane data" do
          let!(:user) { create(:user, email: message["customer"]["email"]) }

          context "response" do
            let(:responder) { handler.process }

            it "is a Hub::Responder" do
              expect(responder.class.name).to eql "Spree::Wombat::Responder"
            end

            it "returns the original request_id" do
              expect(responder.request_id).to eql message["request_id"]
            end

            it "returns http 200" do
              expect(responder.code).to eql 200
            end

            it "returns a summary with the created user email and id" do
              expect(responder.summary).to match /Updated customer with spree@example.com and ID/
            end
          end

        end

      end

    end
  end
end
