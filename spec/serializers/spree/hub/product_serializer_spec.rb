require "spec_helper"

module Spree
  module Wombat
    describe ProductSerializer do

      let(:product) { create(:product) }
      let(:serialized_product) { JSON.parse( ProductSerializer.new(product, root: false).to_json) }

      context "format" do

        it "serializes the price as float" do
          expect(serialized_product["price"].class).to eql Float
        end

        it "serializes the cost price as float" do
          expect(serialized_product["cost_price"].class).to eql Float
        end

        it "serializes the available_on in ISO format" do
          expect(serialized_product["available_on"]).to match /\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/
        end

        it "serializes the slug as permalink" do
          expect(serialized_product["permalink"]).to eql product.slug
        end

        it "serializes the shipping category name as shipping_category" do
          expect(serialized_product["shipping_category"]).to eql product.shipping_category.name
        end

        context 'with sku' do
          it "should assign sku as id" do
            expect(serialized_product["id"]).to eql product.sku
          end
        end

        context 'without sku' do
          let(:product) { create(:product, sku: '') }

          it "should assign sku as id" do
            expect(serialized_product["id"]).to eql product.id
          end
        end

        context "without taxons" do
          it "returns [] for 'taxons'" do
            expect(serialized_product["taxons"]).to eql []
          end
        end

        context "taxons" do

          let!(:taxonomy)     { create(:taxonomy, name: 'Categories')}
          let(:taxon_shirts)  { create(:taxon, name: 't-shirts', :taxonomy => taxonomy, :parent => taxonomy.root ) }
          let(:taxon_hats)    { create(:taxon, name: 'hats', :taxonomy => taxonomy, :parent => taxonomy.root) }
          let(:taxon_awesomehats) { create(:taxon, name: 'awesome hats', :taxonomy => taxonomy, :parent => taxon_hats) }
          let(:taxon_rings)   { create(:taxon, name: 'rings', :taxonomy => taxonomy, :parent => taxonomy.root) }

          let(:taxon2)   { create(:taxon, name: 'modern') }

          before do
            product.stub :taxons => [taxon_shirts, taxon_hats, taxon_awesomehats, taxon_rings, taxon2]
          end

          it "serailizes the taxons as nested arrays" do
            expect(serialized_product["taxons"]).to eql [
              ["Categories", "t-shirts"],
              ["Categories", "hats"],
              ["Categories", "hats", "awesome hats"],
              ["Categories","rings"],
              ["modern"]
            ]
          end

        end

        context "without options" do
          it "returns [] for 'options'" do
            expect(serialized_product["options"]).to eql []
          end
        end

        context "options" do
          let(:product) {create(:product_with_option_types)}
          it "returns an array with the option_types" do
            expect(serialized_product["options"]).to eql ["foo-size"]
          end
        end

        context "without images" do
          it "returns [] for 'images'" do
            expect(serialized_product["images"]).to eql []
          end
        end

        context "images" do

          before do
            ActionController::Base.asset_host = "http://myapp.dev"
            image = File.open(File.expand_path('../../../../fixtures/thinking-cat.jpg', __FILE__))
            3.times.each_with_index do |i|
              product.images.create!(attachment: image, position: i, alt: "variant image #{i}")
            end
          end

          it "serialized the original images for the product" do
            expect(serialized_product["images"].count).to be 3
            dimension_hash = {"height" => 490, "width" => 489}
            3.times.each_with_index do |i|
              expect(serialized_product["images"][i]["url"]).to match /http:\/\/myapp.dev\/spree\/products\/\d*\/original\/thinking-cat.jpg\?\d*/
              expect(serialized_product["images"][i]["position"]).to eql i
              expect(serialized_product["images"][i]["title"]).to eql "variant image #{i}"
              expect(serialized_product["images"][i]["type"]).to eql "original"
              expect(serialized_product["images"][i]["dimensions"]).to eql dimension_hash
            end
          end
        end

        context "without variants" do
          it "returns [] for 'variants'" do
            expect(serialized_product["variants"]).to eql []
          end
        end

        context "with variants" do
          let!(:product) {create(:product_with_option_types)}
          let!(:variant) { create(:variant, :product => product) }
          it "serialized the variant as nested objects" do
            product.reload
            expect(serialized_product["variants"].count).to eql 1
          end
        end
      end

    end
  end
end
