Spree::Shipment.class_eval do
  def bill_to
    order.bill_address
  end

  def ship_to
    order.ship_address
  end
end
