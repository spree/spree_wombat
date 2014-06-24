module Spree
  module Wombat
    module Handler
      class AddOrderHandler < OrderHandlerBase

        def process
          order_params = OrderHandlerBase.order_params(@payload[:order])
          order = Spree::Core::Importer::Order.import(find_spree_user,order_params)
          response "Order number #{order.number} was added"
        end

        private

        def find_spree_user
          Spree.user_class.where(email: @payload[:order][:email]).first_or_create
        end

      end
    end
  end
end
