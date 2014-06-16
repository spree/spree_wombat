module Spree
  module Wombat
    module Handler
      class AddProductHandler < ProductHandlerBase

        def process
          id = @product_payload.delete(:id)
          parent_id = @product_payload.delete(:parent_id)
          taxons = @product_payload.delete(:taxons)
          option_types_params = @product_payload.delete(:options)
          images = @product_payload.delete(:images)
          shipping_category_name = @product_payload.delete(:shipping_category)

          @product_payload[:taxon_ids] = prepare_taxons(taxons)
          option_types = prepare_options(option_types_params)
          @product_payload[:shipping_category_id] = prepare_shipping_category(shipping_category_name)

          if parent_id
            product = Spree::Product.where(id: parent_id).first
            if product
              product.variants.create({ product: product }.merge(@product_payload))
            else
              return response "Parent product with id #{parent_id} not found!", 500
            end
          else
            product = Spree::Product.new(@product_payload)
          end

          if product.save
            master_variant = product.master
            option_types.each do |option_type|
              product.option_types << option_type unless product.option_types.include?(option_type)
            end
            response "Product (#{product.id}) and master variant (#{master_variant.id}) are added"
          else
            response "Could not save the Variant #{product.errors}", 500
          end
        end

      end
    end
  end
end
