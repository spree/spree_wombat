require 'spec_helper'

module Spree
  module Wombat
    describe Handler::UpdateProductHandler do

      before do
        img_fixture = File.open(File.expand_path('../../../../../fixtures/thinking-cat.jpg', __FILE__))
        URI.stub(:parse).and_return img_fixture
      end

      context "#process" do
        let!(:message) do
          hsh = ::Hub::Samples::Product.request
          hsh["product"]["permalink"] = "other-permalink-then-name"
          hsh
        end

        let!(:variant) do
          p = create(:product)
          p.master.update_attributes(sku: message["product"]["sku"])
          p.master
        end

        let(:handler) { Handler::UpdateProductHandler.new(message.to_json) }

        it "updates a product in the storefront" do
          expect {
            handler.process
          }.not_to change{ Spree::Product.count }
        end

        it "adds new variant in the storefront" do
          expect {
            handler.process
          }.to change { Spree::Variant.count }.by 1
        end

        context "and with a permalink" do
          before do
            handler.process
          end

          it "updates store the permalink as the slug" do
            expect(Spree::Product.where(slug: message["product"]["permalink"]).count).to eql 1
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

          it "returns a summary with the updated product and variant id's" do
            expect(responder.summary).to match "updated"
          end
        end
      end
    end
  end
end
