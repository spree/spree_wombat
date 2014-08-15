require 'active_model/serializer'

module Spree
  module Wombat
    class ResponderSerializer < ActiveModel::Serializer
      attributes :request_id, :summary, :backtrace, :objects

      def filter(keys)
        keys.delete(:backtrace) unless object.backtrace.present?
        keys.delete(:objects) unless object.objects.present?
        keys
      end

      def attributes
        hash = super

        if objects = hash.delete(:objects)
          objects.each do |key, array_of_objects|
            hash[key] = array_of_objects
          end
        end

        hash
      end
    end
  end
end
