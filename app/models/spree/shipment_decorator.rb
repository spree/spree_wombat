module Spree
  Shipment.class_eval do
    belongs_to :order, :touch => true

    attr_accessible :order_id, :cost, :shipped_at, :state,
      :inventory_units_attributes, :address_attributes, :channel, :totals,
      :billing_address

  end
end
