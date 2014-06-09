module Spree
  module Wombat
    module Handler
      class OrderHandlerBase < Base

        def self.order_params(order)
          order['number'] = order.delete('id')
          order.delete('status')
          order.delete('totals')

          prepare_address(order, 'shipping_address', 'ship_address_attributes')
          prepare_address(order, 'billing_address', 'bill_address_attributes')

          order['payments_attributes'] = order.fetch('payments', [])
          order.delete('payments')
          order['completed_at'] = order.delete('placed_on') if order.has_key?('placed_on')

          prepare_adjustments order
          rehash_line_items order

          order
        end

        private
        def self.prepare_address(order, source_key, target_key)
          order[target_key] = order.delete(source_key)
          order[target_key]['country'] = {
            'iso' => order[target_key]['country'].upcase }

          order[target_key]['state'] = {
            'name' => order[target_key]['state'].capitalize }
        end

        def self.rehash_line_items(order)
          hash = {}
          order['line_items'].each_index do |i|
            hash[i.to_s] = order['line_items'][i]
          end
          order.delete('line_items')
          order['line_items_attributes'] = hash.delete("name")
        end

        def self.prepare_adjustments(order)
          order['adjustments_attributes'] = order.fetch('adjustments', []).map do |adjustment|
            adjustment['label'] = adjustment.delete('name') if adjustment.has_key?('name')
            adjustment['amount'] = adjustment.delete('value') if adjustment.has_key?('value')
            adjustment
          end
          order.delete('adjustments')
        end
      end
    end
  end
end
