require "spec_helper"

module Spree
  module Wombat
    describe ReimbursementSerializer do
      let(:reimbursement) { create(:reimbursement) }
      let(:serialized_reimbursement) { JSON.parse(ReimbursementSerializer.new(reimbursement, root: false).to_json, symbolize_names: true) }

      context "format" do
        it "sets the id as the reimbursement number" do
          expect(serialized_reimbursement[:id]).to eq reimbursement.number
        end

        it "sets the order id as the order's number" do
          expect(serialized_reimbursement[:order_id]).to eq reimbursement.order.number
        end

        it "sets the total" do
          reimbursement.total = reimbursement.return_items.map(&:total).sum
          expect(serialized_reimbursement[:total]).to eq reimbursement.return_items.map(&:total).sum.to_s
        end

        it "sets the reimbursement status" do
          expect(serialized_reimbursement[:reimbursement_status]).to eq "pending"
        end

        context "the reimbursement has processed" do
          before do
            Spree::RefundReason.create!(name: Spree::RefundReason::RETURN_PROCESSING_REASON, mutable: false)
            reimbursement.perform!
          end

          it "sets the reimbursement status" do
            expect(serialized_reimbursement[:reimbursement_status]).to eq "reimbursed"
          end

          it "sets the refunds" do
            expect(serialized_reimbursement[:refunds]).to be_present
            expect(serialized_reimbursement[:refunds].length).to eq reimbursement.refunds.length
          end

          it "sets the paid amount" do
            expect(serialized_reimbursement[:paid_amount].to_f).to be > 0.0
          end

        end

        it "sets the return items" do
          expect(serialized_reimbursement[:return_items]).to be_present
          expect(serialized_reimbursement[:return_items].length).to eq reimbursement.return_items.length
        end
      end
    end
  end
end
