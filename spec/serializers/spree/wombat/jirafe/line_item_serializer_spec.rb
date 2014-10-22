require "spec_helper"

module Spree
  module Wombat
    module Jirafe
      describe LineItemSerializer do

        let(:line_item) { create(:line_item) }
        let(:serialized_line_item) { JSON.parse(LineItemSerializer.new(line_item, root: false).to_json) }

        it "set's the created_at in ISO format" do
          expect(serialized_line_item["created_at"]).to match /\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/
        end

        it "set's the updated_at in ISO format" do
          expect(serialized_line_item["updated_at"]).to match /\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/
        end

        context "variant" do
          it "is present in the json" do
            expect(serialized_line_item["variant"]).to_not be_nil
          end

          it "contains the variant in the line_item" do
            expect(line_item.variant.sku).to eql serialized_line_item["variant"]["sku"]
          end

        end

      end
    end
  end
end
