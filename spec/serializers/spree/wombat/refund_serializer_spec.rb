require "spec_helper"

module Spree
  module Wombat
    describe RefundSerializer do
      let(:refund) { build(:refund) }
      let(:serialized_refund) { JSON.parse(RefundSerializer.new(refund, root: false).to_json, symbolize_names: true) }

      context "format" do
        it "sets the reason" do
          expect(serialized_refund[:reason]).to match /Refund/
        end

        it "includes the payment" do
          expect(serialized_refund[:payment]).to be_present
        end
      end
    end
  end
end
