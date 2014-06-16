require 'spree/core'

module Spree
  module Wombat
  end
end

require 'spree/wombat/client'
require 'spree/wombat/engine'
require 'spree/wombat/responder'

require 'spree/wombat/handler/base'

require 'spree/wombat/handler/product_handler_base'
require 'spree/wombat/handler/add_product_handler'
require 'spree/wombat/handler/update_product_handler'

require 'spree/wombat/handler/set_inventory_handler'

require 'spree/wombat/handler/shipment_handler_base'
require 'spree/wombat/handler/add_shipment_handler'
require 'spree/wombat/handler/update_shipment_handler'
