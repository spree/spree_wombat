module Spree
  module Wombat
    module Handler
      class AddCustomerReturnHandler < Base

        def process
          return response("Please provide a customer_return payload", 400) if customer_return_params.blank?

          customer_return = CustomerReturn.new(stock_location: stock_location, return_items: return_items)

          if customer_return.return_items.length == 0
            received_items = return_items(true)
            if received_items.present? && received_items.length == intended_quantity
              return response("Customer return #{received_items.first.customer_return.number} has already been processed", 200)
            end
          end

          if customer_return.return_items.length != intended_quantity
            return response("Unable to create the requested amount of return items", 500)
          end

          if customer_return.save
            reimburse_customer_return!(customer_return)
            response "Customer return #{customer_return.id} was added", 200
          else
            response "Customer return could not be created, errors: #{customer_return.errors.full_messages}", 400
          end
        rescue Spree::Reimbursement::IncompleteReimbursementError
          # These items need manual intervention and will be identified and handled separately
          response "Customer return #{customer_return.id} processed but not fully reimbursed", 200
        rescue => e
          response "Customer return could not be fully processed, errors: #{e}", 500
        end

        private

        def stock_location
          StockLocation.find_by!(name: customer_return_params[:stock_location])
        end

        def return_items(include_received = false)
          customer_return_params[:items].flat_map do |item|
            inventory_units = item_inventory_units(item)
            return_items = inventory_units.map(&:current_or_new_return_item)
            return_items = prune_received_return_items(return_items) unless include_received
            return_items = sort_return_items(return_items)

            quantity = item[:quantity].to_i
            quantity = 1 if quantity == 0
            return_items.take(quantity)

          end.compact
        end

        def item_inventory_units(item)
          order = Order.includes(inventory_units: [{ return_items: :return_authorization }, :variant]).find_by(number: item[:order_number])
          order.inventory_units.select { |iu| iu.variant.sku == item[:sku] }
        end

        def customer_return_params
          @payload[:customer_return]
        end

        def intended_quantity
          customer_return_params[:items].map { |i| i[:quantity].to_i }.sum
        end

        def prune_received_return_items(return_items)
          return_items.select { |ri| !ri.received? }
        end

        def sort_return_items(return_items)
          return_items = return_items.sort_by { |ri| -(ri.created_at || DateTime.now).to_i }
          return_items = return_items.sort_by { |ri| ri.return_authorization.try(:number) == customer_return_params[:rma] ? 0 : 1 }
          return_items.sort_by { |ri| ri.persisted? ? 0 : 1 }
        end

        def reimburse_customer_return!(customer_return)
          if customer_return.completely_decided? && !customer_return.fully_reimbursed? && !customer_return.order.has_non_reimbursement_related_refunds?
            reimbursement = Reimbursement.build_from_customer_return(customer_return)
            reimbursement.save!
            reimbursement.perform!
          end
        end
      end
    end
  end
end
