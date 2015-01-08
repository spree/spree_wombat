require "spec_helper"

module Spree
  module Wombat
    describe PaymentSerializer do
      let(:payment) do
        Spree::Payment.new do |p|
          p.amount = 55
          p.number = "0number"
          p.state = "completed"
          p.payment_method = Spree::PaymentMethod.new(name: "P Method")
        end
      end

      let(:subject) { described_class.new(payment, root: false).to_json }

      it "serializes attributes" do
        expect(JSON.parse(subject)["amount"]).to eql payment.amount.to_f
        expect(JSON.parse(subject)["payment_method"]).to eql payment.payment_method.name
        expect(JSON.parse(subject)["number"]).to eql payment.number
        expect(JSON.parse(subject)["status"]).to eql payment.state
      end

      it "serializes the amount as float" do
        expect(JSON.parse(subject)["amount"].class).to eql Float
      end
    end
  end
end
