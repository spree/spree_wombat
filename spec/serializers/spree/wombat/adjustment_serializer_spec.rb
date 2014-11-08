require "spec_helper"

module Spree
  module Wombat
    describe AdjustmentSerializer do

      let(:adjustment) { create(:adjustment, order: create(:order)) }
      let(:serialized_adjustment) { AdjustmentSerializer.new(adjustment, root: false).to_json }

      it "serializes the value as float" do
        expect(JSON.parse(serialized_adjustment)["value"].class).to eql Float
      end

      it "serializes the label as name" do
        expect(JSON.parse(serialized_adjustment)["name"]).to eql adjustment.label
      end

    end
  end
end
