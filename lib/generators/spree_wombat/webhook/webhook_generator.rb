module SpreeWombat
  module Generators
    class WebhookGenerator < Rails::Generators::Base

      desc "Generates a webhook handler class"
      source_root File.expand_path("../templates", __FILE__)
      argument :webhook_name, :type => :string,  desc: "the webhook name to add"

      def generate
        template "webhook.rb.tt", "lib/spree/wombat/handler/#{webhook_name}_handler.rb"
      end

      private
      def handler_class
        webhook_name.camelize + "Handler"
      end

      def handler_object
        webhook_name.split("_").last
      end

    end
  end
end
