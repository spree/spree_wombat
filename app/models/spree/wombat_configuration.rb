module Spree
  class WombatConfiguration < Preferences::Configuration
    preference :batch_size, :integer, default: 10
    preference :connection_id, :string
    preference :connection_token, :string
    preference :push_url, :string, :default => 'https://push.wombat.co'
    preference :push_objects, :array, :default => ["Spree::Order", "Spree::Product", "Cart"]
    preference :payload_builder, :hash, :default => {
      "Spree::Order" => {:serializer => "Spree::Wombat::OrderSerializer", :root => "orders", :filter => "complete", :model => "Spree::Order"},
      "Spree::Product" => {:serializer => "Spree::Wombat::ProductSerializer", :root => "products", :model => "Spree::Product"},
      "Cart" => {:serializer => "Spree::Wombat::OrderSerializer", :root => "carts", :filter => "cart", :model => "Spree::Order"}
    }
    preference :last_pushed_timestamps, :hash, :default => {
      "Spree::Order" => nil,
      "Spree::Product" => nil,
      "Cart" => nil
    }
  end
end
