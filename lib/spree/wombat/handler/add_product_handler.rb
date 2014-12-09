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
            errors = @product.errors.full_messages.join("\n")
            response "Product not valid. #{errors}", 500
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
      end
    end
  end
end
