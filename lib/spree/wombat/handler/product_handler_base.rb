require 'open-uri'

module Spree
  module Wombat
    module Handler
      class ProductHandlerBase < Base

        attr_accessor :params, :children_params, :master_images, :taxons_list, :taxon_ids,
                      :root_options, :properties

        def initialize(message)
          super(message)

          @params = @payload[:product]
          @children_params = @params.delete(:variants)
          #posible master images
          @master_images = @params.delete(:images)
          @taxon_ids = []
          @taxons_list = @params.delete(:taxons)
        end

        def root_product_attrs
          permalink = @params.delete(:permalink)
          shipping_category_name = @params.delete(:shipping_category)
          process_taxons(@taxons_list)
          @root_options = @params.delete(:options)
          @properties = @params.delete(:properties)

          @params[:slug] = permalink if permalink.present?
          @params[:shipping_category_id] = process_shipping_category(shipping_category_name)

          # get the price, since this is a virtual attribute and not in the attribute_names
          price = @params[:price]
          sku = @params[:sku]
          @params = @params.slice *Spree::Product.attribute_names
          @params.delete(:id) # Reject ID as it should be set by database or else it could convert to 0 in postgresql.
          @params[:taxon_ids] = Spree::Taxon.where(id: @taxon_ids).leaves.pluck(:id) unless @taxons_list.nil?
          @params[:price] = price
          @params[:sku] = sku
          @params
        end

        # ['color', 'size']
        def process_option_types(product, options)
          return unless options.present?

          options.each do |option_type_name|
            option_type = Spree::OptionType.where(name: option_type_name).first_or_initialize do |option_type|
              option_type.presentation = option_type_name
              option_type.save!
            end
            product.option_types << option_type unless product.option_types.include?(option_type)
          end
        end

        #{"material" => "cotton", "fit" => "smart fit"}
        def process_properties(product, properties)
          return unless properties.present?
          properties.keys.each do |property_name|
            property = Spree::Property.where(name: property_name).first_or_initialize do |property|
              property.presentation = property_name
              property.save!
            end
            Spree::ProductProperty.where(product: product, property: property).first_or_initialize do |pp|
              pp.value = properties[property_name]
              pp.save!
            end
          end
        end

        def process_shipping_category(shipping_category_name)
          Spree::ShippingCategory.where(name: shipping_category_name).first_or_create.id
        end

        def process_taxons(taxons)
          return unless taxons.present?
          taxons.each do |taxons_path|
            return unless taxons_path.present?
            taxonomy_name = taxons_path.shift
            taxonomy = Spree::Taxonomy.where(name: taxonomy_name).first_or_create
            add_taxon(taxonomy.root, taxons_path)
          end
        end

        # recursive method to add the taxons
        def add_taxon(parent, taxon_names, position = 0)
          return unless taxon_names.present?
          taxon_name = taxon_names.shift
          # first_or_create is broken :(
          taxon = Spree::Taxon.where(name: taxon_name, parent_id: parent.id).first
          if taxon
            parent.children << taxon
          else
            taxon = parent.children.create!(name: taxon_name, position: position)
          end
          parent.save
          # store the taxon so we can assign it later
          @taxon_ids << taxon.id
          add_taxon(taxon, taxon_names, position + 1)
        end

        def process_images(variant, images)
          return unless images.present?

          images.each do |image_hsh|
            variant.images.create!(
              alt: image_hsh["title"],
              attachment: URI.parse(URI.encode(image_hsh["url"].strip)),
              position: image_hsh["position"]
            )
          end
        end

        # adding variants to the product based on the children hash
        def process_child_products(product, children)
          return unless children.present?

          children.each do |child_product|
            option_type_values = child_product.delete(:options)
            images = child_product.delete(:images)
            price = child_product[:price]
            child_product = child_product.slice *Spree::Variant.attribute_names
            child_product[:options] = option_type_values.collect {|k,v| {name: k, value: v} }
            child_product[:price] = price
            variant = product.variants.find_by_sku(child_product[:sku])
            if variant
              variant.update_attributes(child_product)
            else
              variant = product.variants.create!({ product: product }.merge(child_product))
            end
            process_images(variant, images)
          end
        end


      end
    end
  end
end
