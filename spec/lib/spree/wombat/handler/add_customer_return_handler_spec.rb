require 'spec_helper'

shared_examples "receives the return items" do |message=/Customer return \d+ was added/|
  it "succeeds" do
    expect(responder.summary).to match message
    expect(responder.code).to eql 200
  end

  it "creates a valid customer return" do
    expect { subject }.to change { Spree::CustomerReturn.count }.by 1
    customer_return = Spree::CustomerReturn.last
    expect(customer_return).to be_valid
  end

  it "has the correct stock location" do
    subject
    customer_return = Spree::CustomerReturn.last
    expect(customer_return.stock_location.name).to eq stock_location.name
  end

  it "receives all the return items" do
    subject
    customer_return = Spree::CustomerReturn.last
    expect(customer_return.return_items.count).to eq 3
    expect(customer_return.return_items.map(&:reception_status).uniq).to eq ["received"]
  end

  it "attempts to accept all of the return items" do
    accept_count = 0
    original_method = Spree::ReturnItem.instance_method(:attempt_accept)
    Spree::ReturnItem.any_instance.stub(:attempt_accept) do |return_item|
      accept_count += 1
      original_method.bind(return_item).call
    end
    subject
    expect(accept_count).to eq 3
  end
end

shared_examples "does not receive the return items" do
  let(:error_status_code) { 500 }
  let(:error_message) { "Customer return could not be created, errors:" }
  let(:ignore_reception_status) { false }

  it "responds with an error" do
    expect(responder.summary).to match /#{error_message}/
    expect(responder.code).to eql error_status_code
  end

  it "does not create the customer return" do
    expect { subject }.not_to change { Spree::CustomerReturn.count }
  end

  it "does not tell any of the return items to receive" do
    unless ignore_reception_status
      subject
      expect([[], ["awaiting_return"]]).to include Spree::ReturnItem.all.map(&:reception_status).uniq
    end
  end

  it_behaves_like "does not attempt to refund the customer"
end


shared_examples "attempts to refund the customer" do
  it do
    subject
    customer_return = Spree::CustomerReturn.last
    expect(customer_return.reimbursements.count).to eq 1
    reimbursement = customer_return.reimbursements.first
    expect(reimbursement).to be_a Spree::Reimbursement
    expect(customer_return).to be_fully_reimbursed
  end
end

shared_examples "does not attempt to refund the customer" do
  it do
    subject
    customer_return = Spree::CustomerReturn.last
    expect(customer_return.try(:reimbursements)).to be_blank
  end
end

module Spree
  module Wombat
    describe Handler::AddCustomerReturnHandler do

      context "#process" do
        let!(:order) { create(:shipped_order, line_items_count: 3) }
        let!(:rma) { create(:return_authorization, order: order) }
        let!(:shipment) { order.shipments.first }
        let!(:stock_location) { shipment.stock_location }
        let!(:variant_1) { order.inventory_units.first.variant }
        let!(:variant_2) { order.inventory_units.last.variant }


        let(:handler) { Handler::AddCustomerReturnHandler.new(message.to_json) }
        let(:responder) { subject }
        subject { handler.process }

        before do
          order.inventory_units.detect do |iu|
            ![variant_1, variant_2].include? iu.variant
          end.update_attributes!(variant_id: variant_2.id)
          Spree::RefundReason.create!(name: Spree::RefundReason::RETURN_PROCESSING_REASON, mutable: false)
        end

        context "with customer_return payload" do
          let(:message) do
            {
              customer_return: {
                rma: rma.number,
                receipt_date: 5.minutes.ago,
                stock_location: stock_location.name,
                items: [
                  {
                    sku: variant_1.sku,
                    quantity: "1",
                    product_status: "GOOD",
                    order_number: order.number,
                  },
                  {
                    sku: variant_2.sku,
                    quantity: "2",
                    product_status: "DAMAGED",
                    order_number: order.number,
                  }
                ]
              }
            }
          end

          it "returns a Hub::Responder" do
            expect(responder.class.name).to eql "Spree::Wombat::Responder"
          end

          it "has the correct request_id" do
            expect(responder.request_id).to eql message["request_id"]
          end

          context "all return items are for the rma" do
            before do
              order.inventory_units.each { |iu| rma.return_items << iu.current_or_new_return_item }
              rma.save!
            end
            it_behaves_like "receives the return items"
            it_behaves_like "attempts to refund the customer"

            context "there are non-inventory refunds on the order" do
              before do
                order.payments.first.refunds.create!(reimbursement_id: nil, amount: 10.0, reason: build(:refund_reason))
              end
              it_behaves_like "receives the return items"
              it_behaves_like "does not attempt to refund the customer"
            end

            context "the customer return raises an IncompleteReimbursement error" do
              before do
                expect_any_instance_of(Spree::Reimbursement).to(
                  receive(:perform!).and_raise(Spree::Reimbursement::IncompleteReimbursementError)
                )
              end
              it_behaves_like "receives the return items", /Customer return \d+ processed but not fully reimbursed/
            end
          end

          context "there are return items that are not preauthorized" do
            it_behaves_like "receives the return items"
            it_behaves_like "does not attempt to refund the customer"
          end

          context "there are return items that are preauthorized by another rma" do
            let(:other_rma) do
              create(:return_authorization, order: order, return_items: order.inventory_units.map(&:current_or_new_return_item))
            end

            it_behaves_like "receives the return items"
            it_behaves_like "does not attempt to refund the customer"
          end

          context "the rma does not exist" do
            before { rma.destroy! }
            it_behaves_like "receives the return items"
            it_behaves_like "does not attempt to refund the customer"
          end

          context "the order does not exist" do
            before { order.destroy! }
            it_behaves_like "does not receive the return items" do
              let(:error_message) { "Customer return could not be fully processed, errors:" }
            end
          end

          context "the stock location does not exist" do
            before { StockLocation.where(name: stock_location.name).destroy_all }
            it_behaves_like "does not receive the return items" do
              let(:error_message) { "Customer return could not be fully processed, errors:" }
            end
          end

          context "there are not enough items to fulfill the return" do
            before do
              inventory_units = order.inventory_units.take(1)
              Spree::Order.any_instance.stub(:inventory_units) { inventory_units }
            end

            it_behaves_like "does not receive the return items" do
              let(:error_message) { "Unable to create the requested amount of return items" }
            end
          end

          context "items have already been received" do
            context "any of the items could possibly be returned" do
              before do
                Spree::CustomerReturn.create!(
                  return_items: [order.inventory_units.last.return_items.build],
                  stock_location: stock_location
                )
              end

              it_behaves_like "does not receive the return items" do
                let(:error_message) { "Unable to create the requested amount of return items" }
                let(:ignore_reception_status) { true }
              end
            end

            context "none of the items could possibly be returned since they all already have been" do
              before do
                Spree::CustomerReturn.create!(
                  return_items: order.inventory_units.map { |iu| iu.return_items.build },
                  stock_location: stock_location
                )
              end

              it_behaves_like "does not receive the return items" do
                let(:error_status_code) { 200 }
                let(:error_message) { /Customer return \w+ has already been processed/ }
                let(:ignore_reception_status) { true }
              end
            end


          end

          context "there is a mix of created and new return items" do
            let(:return_item) do
              order.inventory_units.order(:id).last.current_or_new_return_item.tap(&:save)
            end

            before do
              rma.return_items << return_item
              rma.save!
            end

            let(:message) do
              {
                customer_return: {
                  rma: rma.number,
                  receipt_date: 5.minutes.ago,
                  stock_location: stock_location.name,
                  items: [
                    {
                      sku: variant_2.sku,
                      quantity: 1,
                      product_status: "DAMAGED",
                      order_number: order.number,
                    }
                  ]
                }
              }
            end

            it "prefers already created return items" do
              expect { subject }.not_to change { Spree::ReturnItem.count }
              customer_return = Spree::CustomerReturn.last
              expect(customer_return.return_items).to eq [return_item]
            end

            it "does not use return items that have already been received" do
              return_item.receive!
              expect { subject }.to change { Spree::ReturnItem.count }
              customer_return = Spree::CustomerReturn.last
              expect(customer_return.return_items.length).to eq 1
              expect(customer_return.return_items).not_to eq [return_item]
            end

            it "prefers created return items that are for the rma requested" do
              other_inventory_unit = order.inventory_units.detect { |i| i.variant == return_item.inventory_unit.variant }
              other_return_item = other_inventory_unit.current_or_new_return_item.tap(&:save)
              other_rma = create(:return_authorization, order: order, return_items: [other_return_item], number: rma.number + "55")

              expect { subject }.not_to change { Spree::ReturnItem.count }
              customer_return = Spree::CustomerReturn.last
              expect(customer_return.return_items).to eq [return_item]
            end

            it "prefers most recent created return items for the same rma" do
              Timecop.travel(1.day.from_now) do
                other_inventory_unit = order.inventory_units.detect { |i| i.variant == return_item.inventory_unit.variant }
                other_return_item = other_inventory_unit.current_or_new_return_item.tap(&:save)
                rma.return_items << other_return_item
                rma.save!
                expect { subject }.not_to change { Spree::ReturnItem.count }
                customer_return = Spree::CustomerReturn.last
                expect(customer_return.return_items).to eq [other_return_item]
              end
            end
          end
          context "the customer return requires manual intervention" do
            before { Spree::CustomerReturn.any_instance.stub(:completely_decided?) { false } }
            it_behaves_like "does not attempt to refund the customer"
          end

          context "the customer return has already been reimbursed" do
            before { Spree::CustomerReturn.any_instance.stub(:fully_reimbursed?) { true } }
            it_behaves_like "does not attempt to refund the customer"
          end
        end

        context "without return items" do
          let(:message) do
            {
              customer_return: {
                rma: rma.number,
                receipt_date: 5.minutes.ago,
                stock_location: stock_location.name,
                items: []
              }
            }
          end

          it_behaves_like "does not receive the return items" do
            let(:error_status_code) { 400 }
          end
        end

        context "without customer_return payload" do
          let(:message) { { a: 1 } }

          it "returns a Hub::Responder" do
            expect(responder.class.name).to eql "Spree::Wombat::Responder"
          end

          it "has the correct request_id" do
            expect(responder.request_id).to eql message["request_id"]
          end

          it "fails" do
            expect(responder.summary).to eql "Please provide a customer_return payload"
            expect(responder.code).to eql 400
          end
        end
      end

    end
  end
end
