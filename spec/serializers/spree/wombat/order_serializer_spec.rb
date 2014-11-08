require "spec_helper"

module Spree
  module Wombat
    describe OrderSerializer do

      let!(:order) { create(:shipped_order) }

      let(:serialized_order) do
        JSON.parse(OrderSerializer.new(order, root: false).to_json)
      end

      context "format" do

        it "uses the order number for id" do
          expect(serialized_order["id"]).to eql order.number
        end

        it "uses status for the state" do
          expect(serialized_order["status"]).to eql order.state
        end

        context '#channel' do
          it "sets the channel to spree if unset" do
            expect(serialized_order["channel"]).to eql "spree"
          end

          it "sets the channel to existing value other than spree" do
            order.update_column :channel, 'wombat'
            expect(serialized_order["channel"]).to eql "wombat"
          end
        end

        it "set's the placed_on to completed_at date in ISO format" do
          expect(serialized_order["placed_on"]).to match /\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/
        end

        context "totals" do

          let(:totals) do
            {
              "item"=> 10.0,
              "adjustment"=> 0.0,
              "tax"=> 0.0,
              "shipping"=> 100.0,
              "payment"=> 110.0,
              "order"=> 110.0
            }
          end

          it "has all the amounts for the order" do
            expect(serialized_order["totals"]).to eql totals
          end
        end

        context "adjustments key" do
          it "shipment matches order shipping total value" do
            shipping_hash = serialized_order["adjustments"].select { |a| a["name"] == "shipping" }.first
            expect(shipping_hash["value"]).to eq order.shipment_total.to_f
          end

          context 'discount' do
            before do
              create(:adjustment, adjustable: order, source_type: 'Spree::PromotionAction', amount: -10, order: order)
              create(:adjustment, adjustable: order.line_items.first, source_type: 'Spree::PromotionAction', amount: -10, order: order)
              create(:adjustment, adjustable: order.shipments.first, source_type: 'Spree::PromotionAction', amount: -10, order: order)
              #create(:adjustment, adjustable: order, source_type: nil, source_id: nil, amount: -10, label: 'Manual discount')
              order.update_totals
            end

            it "discount matches order promo total value" do
              discount_hash = serialized_order["adjustments"].select { |a| a["name"] == "discount" }.first
              expect(discount_hash["value"]).to eq -30.0
            end
          end

          context 'manual tax from import' do
            before do
              create(:adjustment, adjustable: order, source_type: nil, source_id: nil, amount: 1.14, label: 'Tax', order: order)
              order.update_totals
            end

            it "tax_total matches the manual value" do
              expect(serialized_order["totals"]["tax"]).to eql 1.14
            end
          end

        end
      end
    end
  end
end
