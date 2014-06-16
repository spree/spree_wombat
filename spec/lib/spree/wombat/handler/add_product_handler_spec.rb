require 'spec_helper'

module Spree
  module Wombat
    describe Handler::AddProductHandler do

      context "#process" do
        context "with a master product (ie no parent_id)" do

          let!(:message) do
            hsh = ::Hub::Samples::Product.request
            hsh["product"]["parent_id"] = nil
            hsh["product"]["permalink"] = "other-permalink-then-name"
            hsh
          end

          let(:handler) { Handler::AddProductHandler.new(message.to_json) }

          it "imports a new product in the storefront" do
            expect{handler.process}.to change{Spree::Product.count}.by(1)
          end

          it "imports a new variant master in the storefront" do
            expect{handler.process}.to change{Spree::Variant.count}.by(1)
          end

          context "with taxons" do

            context "and no taxons present in Spree" do
              it "will create the taxonomies based on the first item" do
                expect{handler.process}.to change{Spree::Taxonomy.count}.by(2)
                expect(Spree::Taxonomy.find_by_name("Categories")).not_to be_nil
                expect(Spree::Taxonomy.find_by_name("Brands")).not_to be_nil
              end

              it "will create the taxons recursively" do
                expect{handler.process}.to change{Spree::Taxon.count}.by(6)
              end
            end

            context "and some taxons already present in Spree" do
              let!(:taxonomy) {create(:taxonomy, name: "Categories")}
              it "will not create the already existing taxonomy" do
                expect{handler.process}.to change{Spree::Taxonomy.count}.by(1)
              end
              it "will not create the root taxon" do
                expect{handler.process}.to change{Spree::Taxon.count}.by(5)
              end
            end

            it "will nest all properly" do
              handler.process

              # [
              #   ["Categories", "Clothes", "T-Shirts"],
              #   ["Brands", "Spree"],
              #   ["Brands", "Open Source"]
              # ]

              categories = Spree::Taxonomy.find_by_name("Categories")
              brands = Spree::Taxonomy.find_by_name("Brands")

              # just "Clothes"
              expect(categories.root.children.count).to eql 1

              # ["Clothes", "T-Shirts"]
              expect(categories.root.descendants.count).to eql 2

              # just "T-Shirts"
              expect(categories.root.leaves.count).to eql 1

              # "Spree" and "Open Source"
              expect(brands.root.children.count).to eql 2

              # "Spree" and "Open Source"
              expect(brands.root.descendants.count).to eql 2

              # "Spree" and "Open Source"
              expect(brands.root.leaves.count).to eql 2

            end

            it "will assign the taxon leaves to the product" do
              handler.process
              product = Spree::Product.find_by_permalink("other-permalink-then-name")
              expect(product.taxons.count).to eql 3
              product.taxons.each do |taxon|
                expect(taxon.leaf?).to be_true
              end
              expect(product.taxons.pluck(:name)).to eql ["T-Shirts", "Spree", "Open Source"]
            end
          end

          context "with options" do
            context "and no option_types present in Spree" do
              it "will create the option_types" do
                expect{handler.process}.to change{Spree::OptionType.count}.by(2)
              end
            end

            context "and some option_types are present in Spree" do
              let!(:option_type) {create(:option_type, name: "color")}
              it "will only create the missing option_types" do
                expect{handler.process}.to change{Spree::OptionType.count}.by(1)
              end
            end

            # {"color"=>"GREY", "size"=>"S"}
            # Will create the 'color' and 'size' option_types
            it "will assign those option_types to the product" do
              handler.process
              product = Spree::Product.find_by_permalink("other-permalink-then-name")
              expect(product.option_types.pluck(:name)).to eql ["color", "size"]
            end
          end

          context "response" do
            let(:responder) { handler.process }

            it "is a Wombat::Responder" do
              expect(responder.class.name).to eql "Spree::Wombat::Responder"
            end

            it "returns the original request_id" do
              expect(responder.request_id).to eql message["request_id"]
            end

            it "returns http 200" do
              expect(responder.code).to eql 200
            end

            it "returns a summary with the created product and variant id's" do
              expect(responder.summary).to match /Product \(\d+\) and master variant \(\d+\) are added/
            end
          end

        end
      end

    end
  end
end
