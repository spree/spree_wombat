require 'open-uri'

module Spree
  module Wombat
    module Handler
      class UpdateProductHandler < ProductHandlerBase

        def process
          id = params.delete(:id)
          product = Spree::Variant.where(is_master: true, sku: params[:sku]).first.product
          return response("Cannot find product with SKU #{params[:sku]}!", 500) unless product

          Spree::Product.transaction do
            @product = process_root_product(product, root_product_attrs)
            process_images(@product.master, @master_images)
            process_child_products(@product, children_params) if @children_params
          end

          if @product.valid?
            @product.touch

            if @product.variants.count > 0
              response "Product #{@product.sku} updated, with child skus: #{@product.variants.pluck(:sku)}"
            else
              response "Product #{@product.sku} updated"
            end
          else
            response "Cannot update the product due to validation errors", 500
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

        # adding variants to the product based on the children hash
        def process_child_products(product, children)
          return unless children.present?

          children.each do |child_product|

            # used for possible assembly feature.
            quantity = child_product.delete(:quantity)

            option_type_values = child_product.delete(:options)

            child_product[:options] = option_type_values.collect {|k,v| {name: k, value: v} }

            images = child_product.delete(:images)

            variant = product.variants.find_by_sku(child_product[:sku])
            if variant
              variant.update_attributes(child_product)
            else
              variant = product.variants.create({ product_id: product.id }.merge(child_product))
            end
            process_images(variant, images)
          end

        end

      end
    end
  end
end
