require "spec_helper"

module Spree
  module Wombat
    describe LineItemSerializer do

      let(:line_item) { create(:line_item) }
      let(:serialized_line_item) { LineItemSerializer.new(line_item, root: false).to_json }

      it "serializes the product_id" do
        expect(JSON.parse(serialized_line_item)["product_id"]).to eql line_item.variant.sku
      end

      it "serializes the price as float" do
        expect(JSON.parse(serialized_line_item)["price"].class).to eql Float
      end

    end
  end
end
