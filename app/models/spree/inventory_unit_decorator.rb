module Spree
  InventoryUnit.class_eval do
    belongs_to :shipment, :touch => true
    attr_accessible :variant_id, :order_id
  end
end
