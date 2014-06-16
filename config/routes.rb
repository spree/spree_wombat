Spree::Core::Engine.routes.draw do
  namespace :wombat do
    post '*path', to: 'webhook#consume', as: 'webhook'
  end
end
