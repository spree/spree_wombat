Spree::Order.class_eval do
  after_commit :touch_shipments

  private
  def touch_shipments
    self.shipments.collect &:touch
  end
end
