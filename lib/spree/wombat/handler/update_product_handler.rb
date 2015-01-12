require 'open-uri'

module Spree
  module Wombat
    module Handler
      class UpdateProductHandler < ProductHandlerBase

        def process
          id = params.delete(:id)
          variant = Variant.where(is_master: true, sku: params[:sku]).first

          if variant.nil? || variant.product.nil?
            return response("Cannot find product with SKU #{params[:sku]}!", 500)
          end

          product = variant.product

          # Disable the after_touch callback on taxons
          Spree::Product.skip_callback(:touch, :after, :touch_taxons)

          Spree::Product.transaction do
            @product = process_root_product(product, root_product_attrs)
            process_images(@product.master, @master_images)
            process_child_products(@product, children_params) if @children_params
          end

          if @product.valid?
            # set it again, and touch the product
            Spree::Product.set_callback(:touch, :after, :touch_taxons)
            @product.touch

            if @product.variants.count > 0
              response "Product #{@product.sku} updated, with child skus: #{@product.variants.pluck(:sku)}"
            else
              response "Product #{@product.sku} updated"
            end
          else
            errors = @product.errors.full_messages.join("\n")
            response "Product not valid. #{errors}", 500
          end
        end

        # the Spree::Product and Spree::Variant master
        # it's the top level 'product'
        def process_root_product(product, params)
          product.update_attributes(params)
          process_option_types(product, @root_options)
          process_properties(product, @properties)

          product
        end

      end
    end
  end
end
