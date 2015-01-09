# Spree Wombat

Connect your SpreeCommerce Storefront to Wombat, providing push API and webhook handlers

[![Build Status](https://travis-ci.org/spree/spree_wombat.svg?branch=master)](https://travis-ci.org/spree/spree_wombat)

## Installation

Add spree_wombat to your Gemfile:

```ruby
gem 'spree_wombat', git: 'git@github.com:spree/spree_wombat.git', branch: 'master'
```

Bundle your dependencies and run the installation generator:

```shell
bundle
bundle exec rails g spree_wombat:install
```

Add your Wombat credentials to `config/initializers/wombat.rb`:

```ruby
Spree::Wombat::Config.configure do |config|
  config.connection_token = "YOUR TOKEN"
  config.connection_id = "YOUR CONNECTION ID"
end
```

## Configuration

All the configuration is done inside the initializer here: `config/initializers/wombat.rb` all the default settings can be found there as well. Below we will explain all of them

### push_objects

The push_objects is an array of model names that are selected to push to Wombat. We use these as keys in other places as well to configure how the payload is serialized and to keep track of the last time we pushed the objects.

```ruby
config.push_objects = ["Spree::Order", "Spree::Product"]
```

By default we only push `Spree::Order` and `Spree::Product` models.

### payload_builder

To push the data to Wombat we need to configure the way on how to construct the JSON payload.


```ruby
config.payload_builder = {
  "Spree::Order"  => {:serializer => "Spree::Wombat::OrderSerializer", :root => "orders"},
  "Spree::Product" => {:serializer => "Spree::Wombat::ProductSerializer", :root => "products"},
}

```
The payload builder is a hash, the key is the model name we also use in the `push_objects` config.

Each model has a `serializer` and a `root` field that defines the serializer we use to serialize to JSON and the root defines the root node for that JSON.

We have defined serializers for the default objects, you can find them [here](https://github.com/spree/spree_wombat/tree/2-3-stable/app/serializers/spree/wombat)

To push other objects to Wombat, you only need to add an entry in the `push_objects` and the `payload_builder` configurations.


### last_pushed_timestamps

For every model we push to Wombat we keep track when we pushed the objects.

Do not add this in `config/initializers/wombat.rb` otherwise it will reset the data on each restart.

Instead, if you need to reset data or want to update a timestamp for an object you can do so in the console

```shell
timestamps = Spree::Wombat::Config[:last_pushed_timestamps]
timestamps["Spree::Order"] = 2.days.ago
Spree::Wombat::Config[:last_pushed_timestamps] = timestamps
```

This will update the preference in the database and will use your updated timestamp for, in this case, 'Spree::Order'

### WebhookController.error_notifier

If you would like to forward WebhookController exceptions to an error
notification tool you can configure the `WebhookController.error_notifier`
property with an object that responds to `#call` and accepts the responder as an
argument. e.g. with a proc:

```ruby
# in config/initializers/wombat.rb:
Rails.application.config.to_prepare do
  Spree::Wombat::WebhookController.error_notifier = ->(responder) do
    Honeybadger.notify(responder.exception)
  end
end
```

## Push to Wombat

To push objects to Wombat we provide you with the following rake task:

```shell
bundle exec rake wombat:push_it
```

This task will collect all the objects from `push_objects` that are not yet pushed (defined in `last_pushed_timestamps`) and will push those objects in batches of 10 to Wombat.

You could also add a background task to make that happen, all you need there are these lines:

```ruby
Spree::Wombat::Config[:push_objects].each do |object|
  Spree::Wombat::Client.push_batches(object)
end
```

If you want to push Spree::Orders manually for example, you can call this:

```ruby
Spree::Wombat::Client.push_batches("Spree::Order")
```

### push_url

You can override the default url to push your data to. Normally you will not need to change this though.

```ruby
config.push_url = "http://mycustomurl"
```

## Create handler for a webhook

```shell
bundle exec rails g spree_wombat:webhook my_webhook
```

this will generate a handler class for the `my_webhook` webhook in `lib/spree/wombat/handler/my_webhook_handler.rb`

```ruby
module Spree
  module Wombat
    module Handler
      class MyWebhookHandler < Base

        def process
          @webhook = @payload[:webhook]

          #insert code here to handle
        end

      end
    end
  end
end

```


## Create custom serializers

```shell
bundle exec rails g spree_wombat:serializer Spree::Order MyOrderSerializer
```

This will generate a serializer for the provided model name, when the model is already configured in the `payload_builder` we use that serializer name as super class to inherit from. With active_model_serializer you also inherit the attributes so you can keep the existing configuration and only change that what's needed.

The generator will also automatically set the correct configuration in `config/initializers/wombat.rb`

## Testing

First bundle your dependencies, then run `rake`. `rake` will default to building the dummy app if it does not exist, then it will run specs. The dummy app can be regenerated by using `rake test_app`.

```shell
bundle
bundle exec rake
```

Copyright (c) 2014 Spree Commerce, Inc. and other contributors, released under the New BSD License
