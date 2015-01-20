require "spec_helper"

module Spree
  module Wombat
    describe ReturnItemSerializer do
      let(:return_item) { build(:return_item) }
      let(:serialized_return_item) { JSON.parse(ReturnItemSerializer.new(return_item, root: false).to_json, symbolize_names: true) }

      context "format" do
        it "sets the product_id to the variant's sku" do
          expect(serialized_return_item[:product_id]).to eq return_item.inventory_unit.variant.sku
        end

        context "an exchange variant exists" do
          before { return_item.exchange_variant = build(:variant) }
          it "sets the exchange_product_id to the exchange variant's sku" do
            expect(serialized_return_item[:exchange_product_id]).to eq return_item.exchange_variant.sku
          end
        end

        context "a return authorization exists" do
          before { return_item.return_authorization = build(:return_authorization) }
          it "sets the return authorization_id to the return authorization's number" do
            expect(serialized_return_item[:return_authorization_id]).to eq return_item.return_authorization.number
          end
        end

        it "sets the reception status" do
          expect(serialized_return_item[:reception_status]).to eq "awaiting"
        end

        it "sets the acceptance status" do
          expect(serialized_return_item[:acceptance_status]).to eq "pending"
        end

        it "sets the pre_tax_amount" do
          return_item.pre_tax_amount = 5.0.to_d
          expect(serialized_return_item[:pre_tax_amount]).to eq "5.0"
        end

        it "sets the included tax total" do
          return_item.included_tax_total = 5.0.to_d
          expect(serialized_return_item[:included_tax_total]).to eq "5.0"
        end

        it "sets the additional tax total" do
          return_item.additional_tax_total = 5.0.to_d
          expect(serialized_return_item[:additional_tax_total]).to eq "5.0"
        end

        it "sets the id" do
          return_item.save!
          expect(serialized_return_item[:id]).to eq return_item.id
        end

        it 'sets the order number' do
          return_item.save!
          expect(serialized_return_item[:order_number]).to eq return_item.inventory_unit.order.number
        end

        it 'sets the created_at' do
          return_item.save!
          expect(serialized_return_item[:created_at]).to eq return_item.created_at.as_json
        end

        context 'is reimbursed' do
          it 'sets reimbursed to true' do
            return_item.build_reimbursement
            expect(serialized_return_item[:reimbursed]).to eq true
          end

          it 'sets reimbursed_at' do
            return_item.create_reimbursement
            expect(serialized_return_item[:reimbursed_at]).to eq return_item.reimbursement.created_at.as_json
          end
        end

        context 'is not reimbursed' do
          it 'sets reimbursed to false' do
            expect(serialized_return_item[:reimbursed]).to eq false
          end

          it 'does not set reimbursed_at' do
            expect(serialized_return_item[:reimbursed_at]).to eq nil
          end
        end

        it "sets the order's store as the store code" do
          expect(serialized_return_item[:store]).to eq return_item.inventory_unit.order.store.code
        end
      end
    end
  end
end
