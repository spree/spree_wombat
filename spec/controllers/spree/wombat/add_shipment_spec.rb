require 'spec_helper'

module Spree
  describe Wombat::WebhookController do

    let!(:message) {
      {
  "shipment"=> {
    "id"=> "356195",
    "order_id"=> "R063443587",
    "cost"=> "12.0",
    "status"=> nil,
    "shipping_method"=> "UPS Ground",
    "tracking"=> "1ZA282180433242244246",
    "shipped_at"=> "2014-06-08T22=>00=>00-07=>00",
    "shipping_address"=> {
      "firstname"=> "John",
      "lastname"=> "Do",
      "address1"=> "199 Awesome Ave",
      "address2"=> "",
      "zipcode"=> "123456",
      "city"=> "Awesometown",
      "state"=> "PA",
      "country"=> "US",
      "phone"=> "3424253345434"
    },
    "items"=> [
      {
        "name"=> "Oremus-StarterPack",
        "product_id"=> "Oremus-StarterPack",
        "quantity"=> 1
      },
      {
        "name"=> "Oremus-3DVD",
        "product_id"=> "Oremus-3DVD",
        "quantity"=> 2
      }
    ]
  }
}

    }

    let(:parameters) {
      { body: message.to_json, use_route: :spree, format: :json, path: 'add_shipment'}
    }

    let!(:order) do
      order = create(:completed_order_with_totals, number: message["shipment"]["order_id"] )
      2.times do
        create(:line_item, order: order)
      end
      order.update!
      order.reload
    end

    let!(:shipping_method) { create(:shipping_method, name: 'UPS Ground (USD)')}
    let!(:country) { Spree::Country.first }
    let!(:state) { create(:state, :country => country, name: "Pennsylvania", abbr: "PA") }

    before do
      Spree::Variant.stub(:find_by_sku).and_return(order.variants.first)
    end


    context '#consume' do

      context 'with the correct auth' do
        before do
          request.env['HTTP_X_HUB_STORE'] = '234254as3423r3243'
          request.env['HTTP_X_HUB_TOKEN'] = 'abc1233'
        end

        context 'and an existing handler for the webhook' do
          it 'will process the webhook handler' do
            post 'consume', parameters
            json = JSON.parse(response.body)
            binding.pry
            expect(response).to be_success
          end
        end

      end
    end
  end
end
