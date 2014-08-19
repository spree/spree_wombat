require "spec_helper"

module Spree
  module Wombat
    describe OrderSerializer do

      let!(:order) do
        order = create(:completed_order_with_totals)
        2.times do
          create(:line_item, order: order)
        end
        order.update!
        order.reload
      end

      let(:serialized_order) do
        JSON.parse(OrderSerializer.new(order, root: false).to_json)
      end

      before do
        order.update!
      end

      context "format" do

        it "uses the order number for id" do
          expect(serialized_order["id"]).to eql order.number
        end

        it "uses status for the state" do
          expect(serialized_order["status"]).to eql order.state
        end

        it "set's the placed_on to completed_at date in ISO format" do
          expect(serialized_order["placed_on"]).to match /\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/
        end

        context "totals" do

          let(:totals) do
            {
              "item"=> 30.0,
              "adjustment"=> 0.0,
              "discount" => 0.0,
              "tax"=> 0.0,
              "shipping"=> 0.0,
              "payment"=> 0.0,
              "order"=> 30.0
            }
          end

          it "has all the amounts for the order" do
            expect(serialized_order["totals"]).to eql totals
          end
        end

        context "adjustments key" do
          it "shipment matches order shipping total value" do
            shipping_hash = serialized_order["adjustments"].select { |a| a["name"] == "shipping" }.first
            expect(shipping_hash["value"]).to eq order.ship_total.to_f
          end

          context 'discount' do
            before do
              create(:adjustment, adjustable: order, source_type: 'Spree::PromotionAction', amount: -50)
              order.update_totals
            end

            it "discount matches order promo total value" do
              discount_hash = serialized_order["adjustments"].select { |a| a["name"] == "discount" }.first
              expect(discount_hash["value"]).to eq order.promo_total.to_f
            end
          end
        end

      end
    end
  end
end
