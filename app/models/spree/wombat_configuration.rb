module Spree
  class WombatConfiguration < Preferences::Configuration
    preference :connection_id, :string
    preference :connection_token, :string
    preference :push_url, :string, :default => 'https://push.wombat.co'
  end
end
