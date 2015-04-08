require 'active_model_serializers'

module Spree
  module Wombat
    class ResponderSerializer < ActiveModel::Serializer
      attributes :request_id, :summary, :backtrace, :objects

      def attributes
        hash = super

        hash.delete(:backtrace) if object.exception.nil?
        hash.delete(:objects) unless object.objects.present?

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
