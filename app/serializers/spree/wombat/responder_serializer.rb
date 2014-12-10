require 'active_model/serializer'

module Spree
  module Wombat
    class ResponderSerializer < ActiveModel::Serializer
      attributes :request_id, :summary, :backtrace, :objects

      def filter(keys)
        keys.delete(:backtrace) if object.exception.nil?
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

      def backtrace
        object.exception.backtrace.to_s if object.exception
      end

    end
  end
end
