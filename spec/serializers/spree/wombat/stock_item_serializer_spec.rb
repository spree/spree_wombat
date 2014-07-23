require "spec_helper"

module Spree
  module Wombat
    describe StockItemSerializer do

      let!(:variant) { create(:variant) }
      let!(:stock_item) { variant.stock_items.first }
      let!(:serialized_stock_item) { StockItemSerializer.new(stock_item, root: false).to_json }

      context "format" do

        # Note: might use the name here, or add another readeable id to locations.
        it "serializes the StockLocation name for the 'location'" do
          expect(JSON.parse(serialized_stock_item)["location"]).to eql stock_item.stock_location.name
        end

        it "serializes the variant sku for product_id" do
          expect(JSON.parse(serialized_stock_item)["product_id"]).to eql stock_item.variant.sku
        end

        it "serializes the count_on_hand for quantity" do
          expect(JSON.parse(serialized_stock_item)["quantity"]).to eql stock_item.count_on_hand
        end
      end

    end
  end
end
