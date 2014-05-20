module SpreeWombat
  module Generators
    class InstallGenerator < Rails::Generators::Base

      source_root File.expand_path("../templates", __FILE__)
      class_option :auto_run_migrations, :type => :boolean, :default => false

      def add_initializer
        copy_file "wombat.rb", "config/initializers/wombat.rb"
      end

      def add_migrations
        run 'bundle exec rake railties:install:migrations FROM=spree_wombat'
      end

      def run_migrations
        run_migrations = options[:auto_run_migrations] || ['', 'y', 'Y'].include?(ask 'Would you like to run the migrations now? [Y/n]')
        if run_migrations
          run 'bundle exec rake db:migrate'
        else
          puts 'Skipping rake db:migrate, don\'t forget to run it!'
        end
      end
    end
  end
end
