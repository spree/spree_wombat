module Spree
  module Wombat
    module Handler
      class AddOrderHandler < OrderHandlerBase

        def process
          order = Spree::Core::Importer::Order.import(find_spree_user, OrderHandlerBase.order_params(@payload[:order]))
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
