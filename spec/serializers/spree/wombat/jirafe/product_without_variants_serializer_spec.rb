require "spec_helper"

module Spree
  module Wombat
    module Jirafe
      describe ProductWithoutVariantsSerializer do

        let(:product) { create(:product, height: 1, width: 1, depth: 1) }
        let(:serialized_product) { JSON.parse( ProductWithoutVariantsSerializer.new(product, root: false).to_json) }

        context "with taxons" do

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

          context "meta-data" do

            it "contains taxons data" do
              binding.pry
              expect(serialized_product["meta_data"]["jirafe"]["taxons"]).to be_present
              expect(serialized_product["meta_data"]["jirafe"]["taxons"].size).to eql 5

            end

          end

        end

      end
    end
  end
end
