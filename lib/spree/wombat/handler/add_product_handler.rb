require 'open-uri'

module Spree
  module Wombat
    module Handler
      class AddProductHandler < ProductHandlerBase

        def process

          if Spree::Variant.find_by_sku(@params[:sku])
            return response "Product with SKU #{@params[:sku]} already exists!", 500
          end

          # Disable the after_touch callback on taxons
          Spree::Product.skip_callback(:touch, :after, :touch_taxons)

          Spree::Product.transaction do
            @product = process_root_product(root_product_attrs)
            process_images(@product.master, @master_images)
            process_child_products(@product, children_params) if @children_params
          end

          if @product.valid?
            # set it again, and touch the product
            Spree::Product.set_callback(:touch, :after, :touch_taxons)
            @product.touch

            if @product.variants.count > 0
              response "Product #{@product.sku} added, with child skus: #{@product.variants.pluck(:sku)}"
            else
              response "Product #{@product.sku} added"
            end
          else
            response "Cannot add the product due to validation errors", 500
          end
        end

        # the Spree::Product and Spree::Variant master
        # it's the top level 'product'
        def process_root_product(params)
          product = Spree::Product.create!(params)

          process_option_types(product, @root_options)
          process_properties(product, @properties)

          product
        end

        # adding variants to the product based on the children hash
        def process_child_products(product, children)
          return unless children.present?

          children.each do |child_product|

            # used for possible assembly feature.
            quantity = child_product.delete(:quantity)

            option_type_values = child_product.delete(:options)

            child_product[:options] = option_type_values.collect {|k,v| {name: k, value: v} }

            images = child_product.delete(:images)

            variant = product.variants.create({ product: product }.merge(child_product))
            process_images(variant, images)
          end

        end

      end
    end
  end
end
