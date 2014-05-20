require 'json'
require 'openssl'
require 'httparty'
require 'active_model/array_serializer'

module Spree
  module Wombat
    class Client

      def self.push_batches(object)
        ts = Spree::Wombat::Config[:last_pushed_timestamps][object]
        payload_builder = Spree::Wombat::Config[:payload_builder][object]

        ts = Time.now unless ts

        object.constantize.where("updated_at > ?", ts).find_in_batches(batch_size: 10) do |batch|

          payload = ActiveModel::ArraySerializer.new(
            batch,
            each_serializer: payload_builder[:serializer].constantize,
            root: payload_builder[:root]
          ).to_json

          push(payload)

          last_pushed_ts = Spree::Wombat::Config[:last_pushed_timestamps]
          last_pushed_ts[object] = Time.now
          Spree::Wombat::Config[:last_pushed_timestamps] = last_pushed_ts

        end
      end

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
