require "spec_helper"

module Spree
  module Wombat
    describe CustomerReturnSerializer do
      let(:customer_return) { create(:customer_return) }
      let(:serialized_return) { JSON.parse(CustomerReturnSerializer.new(customer_return, root: false).to_json, symbolize_names: true) }

      context "format" do
        it "uses the customer return number for the id" do
          expect(serialized_return[:id]).to eq customer_return.number
        end

        it "uses the stock location name for the stock location" do
          expect(serialized_return[:stock_location]).to eq customer_return.stock_location.name
        end

        context "the customer return is not reimbursed" do
          it "sets fully reimbursed to false" do
            expect(serialized_return[:fully_reimbursed]).to eq false
          end

          it "has no reimbursements" do
            expect(serialized_return[:reimbursements]).to be_blank
          end
        end

        context "the customer return is reimbursed" do
          before do
            Spree::RefundReason.create!(name: Spree::RefundReason::RETURN_PROCESSING_REASON, mutable: false)
            customer_return.return_items.each(&:attempt_accept)
            reimbursement = customer_return.reimbursements.create!(
              return_items: customer_return.return_items,
              order: customer_return.order
            )
            reimbursement.perform!
            customer_return.reload
          end

          it "sets fully reimbursed to true" do
            expect(serialized_return[:fully_reimbursed]).to eq true
          end

          it "includes reimbursements" do
            expect(serialized_return[:reimbursements]).to be_present
          end
        end

        it "sets the channel to spree" do
          expect(serialized_return[:channel]).to eq "spree"
        end

        it "includes return items" do
          expect(serialized_return[:return_items].count).to eq customer_return.return_items.count
        end

        it "sets the resolution path" do # for linking customer service agents for manual intervention
          expect(serialized_return[:resolution_path]).to eq "/admin/orders/#{customer_return.order.number}/customer_returns/#{customer_return.id}/edit"
        end
      end
    end
  end
end
