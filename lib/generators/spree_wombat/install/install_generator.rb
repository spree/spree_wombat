module SpreeWombat
  module Generators
    class InstallGenerator < Rails::Generators::Base

      source_root File.expand_path("../templates", __FILE__)

      def add_initializer
        copy_file "wombat.rb", "config/initializers/wombat.rb"
      end

    end
  end
end
