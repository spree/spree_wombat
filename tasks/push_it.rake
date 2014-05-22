require 'spree/wombat'

namespace :wombat do
  desc 'Push batches to Wombat'
  task :push_it => :environment do

    if Spree::Wombat::Config[:connection_token] == "YOUR TOKEN" || Spree::Wombat::Config[:connection_id] == "YOUR CONNECTION ID"
      abort("[ERROR] It looks like you did not add your Wombat credentails to config/intializers/wombat.rb, please add them and try again. Exiting now")
    end

    Spree::Wombat::Config[:push_objects].each do |object|
      Spree::Wombat::Client.push_batches(object)
    end

  end
end
