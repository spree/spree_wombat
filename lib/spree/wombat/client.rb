require 'json'
require 'openssl'
require 'httparty'
require 'active_model/array_serializer'

module Spree
  module Wombat
    class Client

      def self.push_batches(object)
        object_count = 0

        last_push_time = Spree::Wombat::Config[:last_pushed_timestamps][object] || Time.now
        this_push_time = touch_last_pushed(object)

        payload_builder = Spree::Wombat::Config[:payload_builder][object]

        scope = object.constantize

        if filter = payload_builder[:filter]
          scope = scope.send(filter.to_sym)
        end

        scope.where("updated_at > ? AND updated_at <= ?", last_push_time, this_push_time).find_in_batches(batch_size: 10) do |batch|
          object_count += batch.size
          payload = ActiveModel::ArraySerializer.new(
            batch,
            each_serializer: payload_builder[:serializer].constantize,
            root: payload_builder[:root]
          ).to_json

          push(payload)
        end
        object_count
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

      private
      def self.touch_last_pushed(object)
        last_pushed_ts = Spree::Wombat::Config[:last_pushed_timestamps]
        last_pushed_ts[object] = Time.now
        Spree::Wombat::Config[:last_pushed_timestamps] = last_pushed_ts
        last_pushed_ts[object]
      end

    end
  end
end
