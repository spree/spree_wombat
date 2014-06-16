module Spree
  module Wombat
    module Handler
      class ProductHandlerBase < Base

        attr_accessor :taxon_ids, :product_payload

        def initialize(message)
          super(message)
          @taxon_ids = []
          @product_payload = @payload[:product]
        end

        # taxons are stored as breadcrumbs in an nested array.
        # [["Categories", "Clothes", "T-Shirts"], ["Brands", "Spree"], ["Brands", "Open Source"]]
        def prepare_taxons(taxons)
          return if taxons.empty?

          taxons.each do |taxons_path|
            taxonomy_name = taxons_path.shift
            taxonomy = Spree::Taxonomy.where(name: taxonomy_name).first_or_create
            add_taxon(taxonomy.root, taxons_path)
          end

          Spree::Taxon.where(id: @taxon_ids).leaves.pluck(:id)
        end


        def add_taxon(parent, taxon_names, position = 0)
          return parent if taxon_names.empty?

          taxon_name = taxon_names.shift
          # first_or_create is broken :(
          taxon = Spree::Taxon.where(name: taxon_name, parent_id: parent.id).first
          if taxon
            parent.children << taxon
          else
            taxon = parent.children.create(name: taxon_name, position: position)
          end
          parent.save
          # store the taxon so we can assign it later
          taxon_ids << taxon.id
          add_taxon(taxon, taxon_names, position+1)
        end

        # option types is a key value hash with {option_type_name => option_type_value}
        # {"color"=>"GREY", "size"=>"S"}
        def prepare_options(options)
          return if options.empty?
          option_types = []
          options.each do |name, value|
            option_type = Spree::OptionType.where(name: name).first_or_initialize do |option_type|
              option_type.presentation = name
              option_type.save!
            end
            option_type.option_values.where(name: value).first_or_initialize do |option_value|
              option_value.presentation = value
              option_value.save!
            end
            option_types << option_type
          end
          option_types
        end

        def prepare_shipping_category(shipping_category_name)
          Spree::ShippingCategory.where(name: shipping_category_name).first_or_create.id
        end

      end
    end
  end
end
