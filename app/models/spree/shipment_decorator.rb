Spree::Shipment.class_eval do
  def ship_to
    order.ship_address
  end
end
