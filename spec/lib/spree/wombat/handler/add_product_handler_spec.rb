require 'spec_helper'

module Spree
  module Wombat
    describe Handler::AddProductHandler do

      let(:message) { ::Hub::Samples::Product.request }
      let(:handler) { Handler::AddProductHandler.new(message.to_json) }
      let(:product) { Spree::Variant.find_by_sku(message["product"]["sku"]).product }

      describe ".process_taxons" do
        # taxons are stored as breadcrumbs in an nested array.
        let(:taxons) {[["Categories", "Clothes", "T-Shirts"], ["Brands", "Spree"], ["Brands", "Open Source"]]}

        context "without taxons" do
          let(:taxons) {[]}

          it "will just return" do
            expect(handler.process_taxons(taxons)).to eql nil
          end

          it "will not add any taxons" do
            expect{handler.process_taxons(taxons)}.to_not change{Spree::Taxon.count}
          end

          it "will not add any taxonomies" do
            expect{handler.process_taxons(taxons)}.to_not change{Spree::Taxonomy.count}
          end

          context "with empty taxon paths" do
            let(:taxons) {[[]]}
            it "will just return" do
              expect(handler.process_taxons(taxons)).to eql nil
            end
            it "will not add any taxons" do
              expect{handler.process_taxons(taxons)}.to_not change{Spree::Taxon.count}
            end

            it "will not add any taxonomies" do
              expect{handler.process_taxons(taxons)}.to_not change{Spree::Taxonomy.count}
            end
          end
        end

        context "with taxons" do
          it "will nest all properly" do
            handler.process_taxons(taxons)

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

          context "and no taxons present" do
            it "will add the first item for every nested array as taxonomy if not present yet" do
              # Categories & Brands
              expect{handler.process_taxons(taxons)}.to change{Spree::Taxonomy.count}.by(2)
            end

            it "will add the other elements to the taxonomies" do
              # Brands will only be added 1 time.
              expect{handler.process_taxons(taxons)}.to change{Spree::Taxon.count}.by(6)
            end
          end

          context "and a taxonomy already present" do
            let!(:taxonomy) { create(:taxonomy, name: "Brands") }

            it "will only add the not present taxonomies" do
              expect{handler.process_taxons(taxons)}.to change{Spree::Taxonomy.count}.by(1)
            end
            it "will only add the not present taxons" do
              expect{handler.process_taxons(taxons)}.to change{Spree::Taxon.count}.by(5)
            end
          end

        end

      end

      describe ".add_taxon" do

        let!(:taxonomy) { create(:taxonomy) }
        let!(:parent) { taxonomy.root }

        context "with no taxon_names" do
          let(:taxon_names) { [] }
          it "will just return" do
            expect(handler.add_taxon(parent,taxon_names)).to eql nil
          end
          it "will not add any taxons" do
            expect{handler.add_taxon(parent,taxon_names)}.to_not change{Spree::Taxon.count}
          end
        end

        context "with taxon_names" do
          let(:taxon_names) { ["Clothes", "T-Shirts"] }

          it "will save the taxon_ids for assignment later" do
            handler.add_taxon(parent,taxon_names)
            expect(handler.taxon_ids.size).to eql 2
          end

          context "and no existing taxons" do
            it "will add the taxons " do
              expect{handler.add_taxon(parent, taxon_names)}.to change{Spree::Taxon.count}.by(2)
            end

            # parent_taxon > Clothes > T-Shirts
            it "will nest the taxons inside each other" do
              handler.add_taxon(parent, taxon_names)
              expect(parent.children.count).to eql 1
              expect(parent.descendants.count).to eql 2
              expect(parent.leaves.count).to eql 1
            end
          end

          context "with same taxon already existing" do
            before do
              taxonomy.root.children << create(:taxon, name: "Clothes")
            end
            it "will only add missing taxons" do
              expect{handler.add_taxon(parent, taxon_names)}.to change{Spree::Taxon.count}.by(1)
            end
          end

        end

      end

      describe ".process_images" do

        let(:variant) { create(:product).master }
        let(:images) { message["product"]["images"]}

        context "with empty images" do
          let(:images) {[]}
          it "will just return" do
            expect(handler.process_images(variant,images)).to eql nil
          end
          it "will not add any images" do
            expect{handler.process_images(variant,images)}.to_not change{Spree::Image.count}
          end
        end

        context "with images with valid url" do
          before do
            img_fixture = File.open(File.expand_path('../../../../../fixtures/thinking-cat.jpg', __FILE__))
            Handler::AddProductHandler.any_instance.stub(:open).and_return img_fixture
          end

          it "will download the image and assign it" do
            expect{handler.process_images(variant,images)}.to change{Spree::Image.count}.by(1)
          end
        end

        context "with invalid image url" do
          it "will raise an exception" do
            images.first["url"] = "http://so wrong . com"
            expect { handler.process_images(variant, images) }.to raise_error
          end
        end
      end

      describe ".process_option_types" do
        let(:product) { create(:product) }

        context "with empty options" do
          it "will just return" do
            expect(handler.process_option_types(product, [] )).to be nil
          end
          it "will not add option_types" do
            expect{handler.process_option_types(product,[])}.to_not change{Spree::OptionType.count}
          end
        end

        context "with the option types not yet present" do
          it "will add the option types" do
            expect{handler.process_option_types(product,["color", "size"])}.to change{Spree::OptionType.count}.by(2)
          end
        end

        context "with some option types already present" do
          let!(:option_type){create(:option_type, name: 'color')}
          it "will only create the missing option type" do
            expect{handler.process_option_types(product,["color", "size"])}.to change{Spree::OptionType.count}.by(1)
          end
        end

        it "will assign the option types to the product" do
          handler.process_option_types(product,["color", "size"])
          expect(product.option_types.count).to eql 2
          expect(product.option_types.collect(&:name)).to eql ["color", "size"]
        end
      end

      describe ".process_properties" do
        let(:product) { create(:product) }
        let(:properties) do
          {
            "material" => "cotton",
            "fit" => "smart fit"
          }
        end

        context "with empty properties" do
          let(:properties) { {} }
          it "will just return" do
            expect(handler.process_properties(product, properties)).to be nil
          end
          it "will not add properties" do
            expect{handler.process_properties(product,properties)}.to_not change{Spree::Property.count}
          end
        end

        context "with the properties not yet present" do
          it "will add the properties" do
            expect{handler.process_properties(product,properties)}.to change{Spree::Property.count}.by(2)
          end
        end

        it "will assign the properties to the product" do
          property_names = ["material", "fit"]
          values = ["cotton", "smart fit"]
          handler.process_properties(product,properties)

          expect(product.properties.count).to eql 2
          expect(product.properties.collect(&:name)).to match_array property_names

          property_names.each_with_index do |p,i|
            expect(product.property(p)).to eql values[i]
          end
        end
      end

      describe "#process" do
        before do
          img_fixture = File.open(File.expand_path('../../../../../fixtures/thinking-cat.jpg', __FILE__))
          Handler::AddProductHandler.any_instance.stub(:open).and_return img_fixture
        end

        context "product without children" do
          let(:message) do
            hsh = ::Hub::Samples::Product.request
            hsh["product"].delete("variants")
            hsh
          end
          let(:handler) { Handler::AddProductHandler.new(message.to_json) }

          it "imports a new Spree::Product" do
            expect{handler.process}.to change{Spree::Product.count}.by(1)
          end

          it "imports a new Spree::Variant (the master)" do
            expect{handler.process}.to change{Spree::Variant.count}.by(1)
          end

          it "returns the correct response" do
            responder = handler.process
            expect(responder.class.name).to eql "Spree::Wombat::Responder"
            expect(responder.request_id).to eql message["request_id"]
            expect(responder.summary).to match "Product #{message["product"]["id"]} added"
          end

          context "processed" do
            before do
              handler.process
            end
            let(:product) { Spree::Variant.find_by_sku(message["product"]["sku"]).product}

            it "will set the correct permalink" do
              expect(product.permalink).to eql message["product"]["permalink"]
            end

            it "will assign the taxons" do
              expect(product.taxons.count).to eql 3
              product.taxons.each do |taxon|
                expect(taxon.leaf?).to be true
              end
              expect(product.taxons.pluck(:name)).to eql ["T-Shirts", "Spree", "Open Source"]
            end

            it "will assign the shipping category" do
              expect(product.shipping_category.name).to eql message["product"]["shipping_category"]
            end

            it "will assign the images to the master variant" do
              expect(product.images.count).to eql 1
            end
          end
        end

        context "product with children" do
          let(:message) {::Hub::Samples::Product.request}
          let(:handler) { Handler::AddProductHandler.new(message.to_json) }

          it "will add variants to the product" do
            # 1 variant as the master, and 1 from the children hash
            expect{handler.process}.to change{Spree::Variant.count}.by(2)
          end

          it "will assign the correct product" do
            handler.process
            expect(product.variants.count).to be 1
          end

          it "sets the correct attributes" do
            handler.process
            variant = Spree::Variant.find_by_sku("SPREE-T-SHIRT-S")
            expect(variant).to_not be_nil
            expect(variant.price.to_f).to eql 39.99
          end

          it "returns the correct response" do
            responder = handler.process
            expect(responder.class.name).to eql "Spree::Wombat::Responder"
            expect(responder.request_id).to eql message["request_id"]
            expect(responder.summary).to eql "Product #{message["product"]["id"]} added, with child skus: #{product.variants.pluck(:sku)}"
          end

          context "with no options hash on product" do
            let(:message) do
              msg = ::Hub::Samples::Product.request
              msg["product"].delete("options")
              msg
            end

            it "adds the correct option types on the variant" do
              responder = handler.process
              variant = Spree::Variant.find_by_sku("SPREE-T-SHIRT-S")
              expect(variant).to_not be_nil
              expect(variant.option_values.collect(&:name)).to eql ["GREY", "S"]
            end
          end

        end
      end

    end
  end
end
