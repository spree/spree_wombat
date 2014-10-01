require 'spec_helper'

module Spree
  module Wombat

    describe Handler::Base do

      context "#initialize" do

        let(:sample_request) {::Hub::Samples::Order.request}
        let(:base_handler) {Handler::Base.new(sample_request.to_json)}

        it "will set the request_id" do
          expect(base_handler.request_id).to_not be_nil
        end

        context "with message without parameters" do
          it "will set the parameters as an empty hash" do
            expect(base_handler.parameters).to be_empty
          end
        end

        context "with message that has parameters" do
          let(:params) { {"key1" => "value1", "key2" => "value2"} }
          let(:sample_request) {::Hub::Samples::Order.request.merge({"parameters" => params})}

          it "will set the correct parameters" do
            expect(base_handler.parameters).to eql params
          end
        end
      end

      context "#build_handler" do

        context "for the called webhook" do
          it "will return the webhook handler" do
            expect(Handler::Base.build_handler("add_order", ::Hub::Samples::Order.request.to_json).class.name).to eql "Spree::Wombat::Handler::AddOrderHandler"
          end
        end
      end

      context "#wombat_objects_for" do

        context "order" do
          let!(:order) { create(:shipped_order) }

          context "with shipment configured" do

            before do
              push_objects = Spree::Wombat::Config[:push_objects]
              push_objects << "Spree::Shipment"
              push_objects << "Spree::Order"
              Spree::Wombat::Config[:push_objects] = push_objects.uniq

              payload_builder = Spree::Wombat::Config[:payload_builder]
              payload_builder["Spree::Shipment"] = {serializer: "Spree::Wombat::ShipmentSerializer", root: "shipments"}
              payload_builder["Spree::Order"] = {serializer: "Spree::Wombat::OrderSerializer", root: "orders"}
              Spree::Wombat::Config[:payload_builder] = payload_builder
            end

            it "returns the order and the shipments JSON objects" do
              wombat_objects_hash = Handler::Base.wombat_objects_for(order)
              expect(wombat_objects_hash["orders"]).to_not be nil
              expect(wombat_objects_hash["shipments"]).to_not be nil
              expect(wombat_objects_hash["shipments"].size).to eql order.shipments.count
            end

          end

          context "without shipment configured" do

            before do
              push_objects = Spree::Wombat::Config[:push_objects]
              push_objects.delete "Spree::Shipment"
              Spree::Wombat::Config[:push_objects] = push_objects.uniq

              payload_builder = Spree::Wombat::Config[:payload_builder]
              payload_builder.delete("Spree::Shipment")
              Spree::Wombat::Config[:payload_builder] = payload_builder
            end

            it "returns only the order JSON object" do
              wombat_objects_hash = Handler::Base.wombat_objects_for(order)
              expect(wombat_objects_hash["orders"]).to_not be nil
              expect(wombat_objects_hash["shipments"]).to be nil
            end
          end
        end

        context "shipment" do
          let!(:shipment) { create(:shipment, order: create(:order_with_line_items)) }

          context "with order configured" do

            before do
              push_objects = Spree::Wombat::Config[:push_objects]
              push_objects << "Spree::Shipment"
              push_objects << "Spree::Order"
              Spree::Wombat::Config[:push_objects] = push_objects.uniq

              payload_builder = Spree::Wombat::Config[:payload_builder]
              payload_builder["Spree::Shipment"] = {serializer: "Spree::Wombat::ShipmentSerializer", root: "shipments"}
              payload_builder["Spree::Order"] = {serializer: "Spree::Wombat::OrderSerializer", root: "orders"}
              Spree::Wombat::Config[:payload_builder] = payload_builder
            end

            it "returns the order and all the shipments for that order as JSON objects" do
              wombat_objects_hash = Handler::Base.wombat_objects_for(shipment)
              expect(wombat_objects_hash["orders"]).to_not be nil
              expect(wombat_objects_hash["shipments"]).to_not be nil
              expect(wombat_objects_hash["shipments"].size).to eql shipment.order.shipments.count
            end
          end

          context "without order configured" do
            before do
              push_objects = Spree::Wombat::Config[:push_objects]
              push_objects.delete "Spree::Order"
              Spree::Wombat::Config[:push_objects] = push_objects.uniq

              payload_builder = Spree::Wombat::Config[:payload_builder]
              payload_builder.delete("Spree::Order")
              Spree::Wombat::Config[:payload_builder] = payload_builder
            end

            it "only returns the shipments and not the order itself as JSON objects" do
              wombat_objects_hash = Handler::Base.wombat_objects_for(shipment)
              expect(wombat_objects_hash["orders"]).to be nil
              expect(wombat_objects_hash["shipments"]).to_not be nil
              expect(wombat_objects_hash["shipments"].size).to eql shipment.order.shipments.count
            end

          end
        end

      end

    end
  end
end
