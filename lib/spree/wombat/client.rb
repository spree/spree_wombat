require 'json'
require 'openssl'
require 'httparty'
require 'active_model/array_serializer'
require 'wombat'

module Spree
  module Wombat
    class Client

      def self.push_batches(object, ts_offset = 5)
        object_count = 0

        last_push_time = Spree::Wombat::Config[:last_pushed_timestamps][object] || Time.now
        this_push_time = Time.now

        payload_builder = Spree::Wombat::Config[:payload_builder][object]

        model_name = payload_builder[:model].present? ? payload_builder[:model] : object

        scope = model_name.constantize

        if filter = payload_builder[:filter]
          scope = scope.send(filter.to_sym)
        end

        # go 'ts_offset' seconds back in time to catch missing objects
        last_push_time = last_push_time - ts_offset.seconds

        scope.where(updated_at: last_push_time...this_push_time).find_in_batches(batch_size: Spree::Wombat::Config[:batch_size]) do |batch|
          object_count += batch.size
          payload = ActiveModel::ArraySerializer.new(
            batch,
            each_serializer: payload_builder[:serializer].constantize,
            root: payload_builder[:root]
          ).to_json

          ::Wombat::Client.push(payload, configuration) unless object_count == 0
        end

        update_last_pushed(object, this_push_time) unless object_count == 0
        object_count
      end

      private

      def self.configuration
        {
          push_url: Spree::Wombat::Config[:push_url],
          connection_id: Spree::Wombat::Config[:connection_id],
          connection_token: Spree::Wombat::Config[:connection_token],
        }
      end

      def self.update_last_pushed(object, new_last_pushed)
        last_pushed_ts = Spree::Wombat::Config[:last_pushed_timestamps]
        last_pushed_ts[object] = new_last_pushed
        Spree::Wombat::Config[:last_pushed_timestamps] = last_pushed_ts
      end
    end
  end
end
