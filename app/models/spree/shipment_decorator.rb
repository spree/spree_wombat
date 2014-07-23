Spree::Shipment.class_eval do

  attr_accessible :order_id, :cost, :shipped_at, :state,
    :inventory_units_attributes, :address_attributes

  def ship_to
    order.ship_address
  end
end
