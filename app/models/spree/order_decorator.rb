Spree::Order.class_eval do
  after_commit :touch_shipments

  private
  def touch_shipments
    self.shipments.update_all(updated_at: Time.now)
  end
end
