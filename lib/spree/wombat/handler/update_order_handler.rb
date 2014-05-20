module Spree
  module Wombat
    module Handler
      class UpdateOrderHandler < OrderHandlerBase

        def process
          order_number = @payload[:order][:id]
          order = Spree::Order.lock(true).find_by(number: order_number)
          return response("Order with number #{order_number} was not found", 500) unless order
          params = {
            state: @payload[:order][:status],
            email: @payload[:order][:email]
          }
          order.update_attributes!(params)
          response "Updated Order with number #{order_number}"
        end
      end
    end
  end
end
