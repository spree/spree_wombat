require 'spec_helper'

module Spree
  module Wombat
    describe Handler::AddCustomerHandler do

      let(:message) { ::Hub::Samples::Customer.request }
      let(:handler) { Handler::AddCustomerHandler.new(message.to_json) }

      let!(:country) { create(:country) }
      let!(:state) { create(:state, :country => country, name: "California", abbr: "CA") }

      context "process" do

        context "sane data" do
          it "imports a new Spree.user_class" do
            expect{handler.process}.to change{Spree.user_class.count}.by(1)
          end

          context "addresses" do
            it "adds the shipping and billing addresses" do
              expect{handler.process}.to change{Spree::Address.count}.by(2)
            end

            it "assigns the address to the user" do
              handler.process
              user = Spree.user_class.where(email: message["customer"]["email"]).first
              expect(user.ship_address).to_not be_nil
              expect(user.bill_address).to_not be_nil
            end

            it "assignes the firstname and lastname to the addresses" do
              handler.process
              user = Spree.user_class.where(email: message["customer"]["email"]).first
              expect(user.bill_address.firstname).to eql message["customer"]["firstname"]
              expect(user.bill_address.lastname).to eql message["customer"]["lastname"]
              expect(user.ship_address.firstname).to eql message["customer"]["firstname"]
              expect(user.ship_address.lastname).to eql message["customer"]["lastname"]
            end
          end

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
              expect(responder.summary).to match /Added new customer with spree@example.com and ID/
            end
          end

        end

      end

    end
  end
end
