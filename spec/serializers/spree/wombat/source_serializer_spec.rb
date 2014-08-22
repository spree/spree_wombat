require "spec_helper"

module Spree
  module Wombat
    describe SourceSerializer do

      context 'when Check' do
        let(:source) do
          Spree::PaymentMethod::Check.new do |s|
            s.name = "Joe Smith"
          end
        end

        let(:subject) { described_class.new(source, root: false).to_json }

        it "serializes attributes" do
          expect(JSON.parse(subject)["source_type"]).to eql source.class.to_s
          expect(JSON.parse(subject)["name"]).to eql source.name
          expect(JSON.parse(subject)["cc_type"]).to eql 'N/A'
          expect(JSON.parse(subject)["last_digits"]).to eql 'N/A'
        end
      end

      context 'when CreditCard' do
        let(:source) do
          Spree::CreditCard.new do |s|
            s.name = "Joe Smith"
            s.cc_type = "visa"
            s.last_digits = "1111"
          end
        end

        let(:subject) { described_class.new(source, root: false).to_json }

        it "serializes attributes" do
          expect(JSON.parse(subject)["source_type"]).to eql source.class.to_s
          expect(JSON.parse(subject)["name"]).to eql source.name
          expect(JSON.parse(subject)["cc_type"]).to eql source.cc_type
          expect(JSON.parse(subject)["last_digits"]).to eql source.last_digits
        end
      end

    end
  end
end
