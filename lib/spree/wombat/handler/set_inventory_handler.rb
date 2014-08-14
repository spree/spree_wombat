module Spree
  module Wombat
    module Handler
      class SetInventoryHandler < Base

        def process
          stock_location_name = @payload[:inventory][:location]

          stock_location = Spree::StockLocation.find_by_name(stock_location_name) || Spree::StockLocation.find_by_admin_name(stock_location_name)
          return response("Stock location with name #{stock_location_name} was not found", 500) unless stock_location

          sku = @payload[:inventory][:product_id]
          variant = Spree::Variant.find_by_sku(sku)
          return response("Product with SKU #{sku} was not found", 500) unless variant

          stock_item = stock_location.stock_items.where(variant: variant).first

          return response("Stock location '#{stock_location_name}' does not has any stock_items for #{sku}", 500) unless stock_item

          count_on_hand = stock_item.count_on_hand
          stock_item.set_count_on_hand(@payload[:inventory][:quantity])

          return response("Set inventory for #{sku} at #{stock_location_name} from #{count_on_hand} to #{stock_item.reload.count_on_hand}")
        end

      end
    end
  end
end
