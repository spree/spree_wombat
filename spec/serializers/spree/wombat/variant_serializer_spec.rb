require "spec_helper"

module Spree
  module Wombat
    describe VariantSerializer do

      let(:variant) { create(:variant) }
      let(:serialized_variant) { JSON.parse( VariantSerializer.new(variant, root: false).to_json) }

      context "format" do

        it "serializes the price as float" do
          expect(serialized_variant["price"].class).to eql Float
        end

        it "serializes the cost price as float" do
          expect(serialized_variant["cost_price"].class).to eql Float
        end

        it "serializes weight & dimensions" do
          expect(serialized_variant['weight']).to  be_present
          expect(serialized_variant['height']).to  be_present
          expect(serialized_variant['width']).to  be_present
          expect(serialized_variant['depth']).to  be_present
        end

        context "without options" do

          let(:variant) { create(:product).master }

          it "returns {} for 'options'" do
            expect(serialized_variant["options"].class).to eql Hash
            expect(serialized_variant["options"]).to be_empty
          end

        end

        context "options" do
          it "returns a hash with 'option_type => value'" do
            options_hash = {"Size" => "S"}
            expect(serialized_variant["options"]).to eql options_hash
          end
        end

        context "without images" do
          it "returns [] for 'images'" do
            expect(serialized_variant["images"]).to eql []
          end
        end

        context "images" do
          before do
            ActionController::Base.asset_host = "http://myapp.dev"
            image = File.open(File.expand_path('../../../../fixtures/thinking-cat.jpg', __FILE__))
            3.times.each_with_index do |i|
              variant.images.create!(attachment: image, alt: "variant image #{i}")
            end
          end

          it "serialized the original images for the variant" do
            expect(serialized_variant["images"].count).to be 3
            dimension_hash = {"height" => 490, "width" => 489}
            3.times.each_with_index do |i|
              expect(serialized_variant["images"][i]["url"]).to match /http:\/\/myapp.dev\/spree\/products\/\d*\/original\/thinking-cat.jpg\z/
              expect(serialized_variant["images"][i]["position"]).to eql (i + 1)
              expect(serialized_variant["images"][i]["title"]).to eql "variant image #{i}"
              expect(serialized_variant["images"][i]["type"]).to eql "original"
              expect(serialized_variant["images"][i]["dimensions"]).to eql dimension_hash
            end
          end
        end

      end

    end
  end
end
