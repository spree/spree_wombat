require 'json'
require 'openssl'
require 'httparty'

module Spree
  module Wombat
    class Client

      def self.push(json_payload)
        HTTParty.post(
          Spree::Wombat::Config[:push_url],
          {
            body: json_payload,
            headers: {
             'Content-Type'       => 'application/json',
             'X-Hub-Store'        => Spree::Wombat::Config[:connection_id],
             'X-Hub-Access-Token' => Spree::Wombat::Config[:connection_token],
             'X-Hub-Timestamp'    => Time.now.utc.to_i.to_s
            }
          }
        )
      end

    end
  end
end
