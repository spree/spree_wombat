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

    end
  end
end
