require "spec_helper"

module Spree
  module Wombat
    describe Client do

      let!(:order) { create(:shipped_order) }

      describe ".push_batches" do
        it "pushes all orders updated recently" do
          second_order = create(:shipped_order)
          expect(Wombat::Client).to receive(:push).with({
            "orders" => [
              OrderSerializer.new(order, root: false),
              OrderSerializer.new(second_order, root: false)
            ]
          }.to_json)
          Client.push_batches(order.class.to_s)
        end

        it "uses the payload root" do
          stubbed_config = {
            :last_pushed_timestamps => {
              "Spree::Order" => Time.now
            },
            :payload_builder => {
              "Spree::Order" => {
                :serializer => "Spree::Wombat::OrderSerializer",
                :root => "godzilla"
              }
            }
          }

          stub_config("Spree::Order", stubbed_config)

          expect(Wombat::Client).to receive(:push).with({"godzilla" => [OrderSerializer.new(order, root: false)]}.to_json)
          Client.push_batches(order.class.to_s)
        end

        it "respects the timestamp offset" do
          old_order = create(:shipped_order)
          old_order.update_column(:updated_at, Time.now - 4.minutes)
          older_order = create(:shipped_order)
          older_order.update_column(:updated_at, Time.now - 10.minutes)
          expect(Wombat::Client).to receive(:push).with({
            "orders" => [
              OrderSerializer.new(order, root: false),
              OrderSerializer.new(old_order, root: false)
            ]
          }.to_json)
          Client.push_batches(order.class.to_s, 5.minutes)
        end

        it "uses the filter" do
          stubbed_config = {
            :payload_builder => {
              "Spree::Order" => {
                :serializer => "Spree::Wombat::OrderSerializer",
                :root => "orders",
                :filter => "incomplete"
              }
            }
          }
          stub_config("Spree::Order", stubbed_config)

          order_2 = create(:order, completed_at: nil)

          expect(Wombat::Client).to receive(:push).with({"orders" => [OrderSerializer.new(order_2, root: false)]}.to_json)

          Client.push_batches(order.class.to_s)
        end
      end
    end
  end
end

def stub_config(class_name, options={})
  options[:last_pushed_timestamps]  ||= {class_name => Spree::Wombat::Config[:last_pushed_timestamps][class_name.to_s]}
  options[:payload_builder]         ||= {class_name => Spree::Wombat::Config[:payload_builder][class_name.to_s]}
  options[:batch_size]              ||= Spree::Wombat::Config[:batch_size]
  options[:push_url]                ||= Spree::Wombat::Config[:push_url]
  options[:connection_id]           ||= Spree::Wombat::Config[:connection_id]
  options[:connection_token]        ||= Spree::Wombat::Config[:connection_token]

  options.each_pair do |key, value|
    allow(Spree::Wombat::Config).to receive(:[]).with(key).and_return(value)
  end
end
