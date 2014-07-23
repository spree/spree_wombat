require "spec_helper"

module Spree
  module Wombat
    describe SourceSerializer do
      let(:source) do
        Spree::CreditCard.new do |s|
          s.cc_type = "visa"
          s.last_digits = "1111"
        end
      end

      let(:subject) { described_class.new(source, root: false).to_json }

      it "serializes attributes" do
        expect(JSON.parse(subject)["cc_type"]).to eql source.cc_type
        expect(JSON.parse(subject)["last_digits"]).to eql source.last_digits
      end
    end
  end
end
