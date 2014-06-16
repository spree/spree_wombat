module Spree
  module Wombat
    module Handler
      class SetInventoryHandler < Base

        def process

          sku = @payload[:inventory][:product_id]
          variant = Spree::Variant.find_by_sku(sku)
          return response("Product with id #{sku} was not found", 500) unless variant

          count_on_hand = variant.count_on_hand
          variant.on_hand = @payload[:inventory][:quantity]
          variant.save

          return response("Set inventory for Product with id #{sku} from #{count_on_hand} to #{variant.count_on_hand}")
        end

      end
    end
  end
end
