Spree::Wombat::Config.configure do |config|

  config.connection_token = "YOUR TOKEN"
  config.connection_id = "YOUR CONNECTION ID"

  #config.push_url = "https://push.wombat.co"

  # config.push_objects = ["Spree::Order", "Spree::Product"]
  # config.payload_builder = {
  #   "Spree::Order" => {:serializer => "Spree::Wombat::OrderSerializer", :root => "orders"},
  #   "Spree::Product" => {:serializer => "Spree::Wombat::ProductSerializer", :root => "products"},
  # }
  # config.last_pushed_timestamps = {
  #   "Spree::Order" => nil,
  #   "Spree::Product" => nil
  # }

end
