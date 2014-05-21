module SpreeWombat
  module Generators
    class SerializerGenerator < Rails::Generators::Base

      desc "Generates a serializer"
      source_root File.expand_path("../templates", __FILE__)
      argument :model_name, type: :string, desc: "the model name for the serializer (Spree::Shipment)"
      argument :serializer_name, type: :string, desc: "the name for the new serializer (MyShipmentSerializer)"

      attr_accessor :superclass

      def generate
        payload_builder = Spree::Wombat::Config[:payload_builder]
        root_sample = model_name.demodulize.underscore.pluralize.downcase

        if payload_builder.keys.include?(model_name)
          self.superclass = payload_builder[model_name][:serializer]
        else
          self.superclass = "ActiveModel::Serializer"
        end
        template "serializer.rb.tt", "app/serializers/#{serializer_name.underscore}.rb"

        payload_builder[model_name] = { :serializer => serializer_name, :root => root_sample}

        append_file 'config/initializers/wombat.rb', "Spree::Wombat::Config[:payload_builder] = #{payload_builder}\n\n"

      end
    end
  end
end
