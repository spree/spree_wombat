require 'active_model/serializer'

module Spree
  module Wombat
    module Jirafe
      class OrderSerializer < Wombat::OrderSerializer

        attributes :number, :visit_id, :visitor_id

        has_many :line_items,  serializer: Spree::Wombat::Jirafe::LineItemSerializer

        def number
          object.number
        end

        def placed_on
          if object.completed_at?
            object.completed_at.getutc.try(:iso8601)
          else
            object.created_at.getutc.try(:iso8601)
          end
        end

      end
    end
  end
end
