Spree::Shipment.class_eval do
  def ship_to
    self.address || order.ship_address
  end
end
