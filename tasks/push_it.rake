require 'spree/wombat'

namespace :wombat do
  desc 'Push batches to Wombat'
  task :push_it => :environment do

    if Spree::Wombat::Config[:connection_token] == "YOUR TOKEN" || Spree::Wombat::Config[:connection_id] == "YOUR CONNECTION ID"
      abort("[ERROR] It looks like you did not add your Wombat credentails to config/intializers/wombat.rb, please add them and try again. Exiting now")
    end
    puts "\n\n"
    puts "Starting pushing objects to Wombat"
    Spree::Wombat::Config[:push_objects].each do |object|
      objects_pushed_count = Spree::Wombat::Client.push_batches(object)
      puts "Pushed #{objects_pushed_count} #{object} to Wombat"
    end
  end
end
