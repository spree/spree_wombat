require "spec_helper"

module Spree
  module Wombat
    describe InventoryUnitSerializer do

      let(:shipment) { create(:shipment, address: create(:address), order: create(:order_with_line_items)) }
      let(:inventory_unit) { shipment.inventory_units.first }
      let(:serialized_inventory_unit) { JSON.parse (InventoryUnitSerializer.new(inventory_unit, root: false).to_json) }

      context "the inventory unit has a quantity field" do #coming soon"
        before do
          inventory_unit.instance_eval do
            def quantity; 2; end
          end
        end

        it "serializes the quantity" do
          expect(serialized_inventory_unit["quantity"]).to eql 2
        end
      end

      context "the inventory does not have a quantity field" do #coming soon"
        it "serializes the quantity as 1" do
          expect(serialized_inventory_unit["quantity"]).to eql 1
        end
      end

      it "serializes the line item price as the price" do
        expect(serialized_inventory_unit["price"]).to eql inventory_unit.line_item.price.round(2).to_f
      end

      it "serializes the variant's sku as the product_id" do
        expect(serialized_inventory_unit["product_id"]).to eql inventory_unit.variant.sku
      end

      it "serializes the variant's name as the name" do
        expect(serialized_inventory_unit["name"]).to eql inventory_unit.variant.name
      end
    end
  end
end
