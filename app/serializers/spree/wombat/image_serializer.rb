require 'active_model_serializers'

module Spree
  module Wombat
    class ImageSerializer < ActiveModel::Serializer
      attributes :url, :position, :title, :type, :dimensions

      def url
        add_host_prefix(object.attachment.url(:original)).gsub(/\?.*/, '')
      end

      def title
        object.alt
      end

      def type
        "original"
      end

      def dimensions
        {
          height: object.attachment_height,
          width: object.attachment_width
        }
      end

      private

      def add_host_prefix(url)
        return url unless ActionController::Base.asset_host
        URI.join(ActionController::Base.asset_host, url).to_s
      end

    end
  end
end
