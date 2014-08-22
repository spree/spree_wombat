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
      end
    end
  end
end
