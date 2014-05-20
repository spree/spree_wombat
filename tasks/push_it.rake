require 'wombat'

namespace :wombat do
  desc 'Push batches to Wombat'
  task :push_it do
    Spree::Wombat::Config[:push_objects].each do |object|
      Spree::Wombat::Client.push_batches(object)
    end
  end
end
