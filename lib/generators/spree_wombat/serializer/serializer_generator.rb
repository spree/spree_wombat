module SpreeWombat
  module Generators
    class SerializerGenerator < Rails::Generators::Base

      desc "Generates a serializer for "
      source_root File.expand_path("../templates", __FILE__)
      argument :model_name, type: :string, desc: "the model name for the serializer (Spree::Shipment)"
      argument :serializer_name, type: :string, desc: "the name for the new serializer (MyShipmentSerializer)"

      def generate
        template "serializer.rb.tt", "app/serializers/#{serializer_name}_handler.rb"
      end
    end
  end
end
