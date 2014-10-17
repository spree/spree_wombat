require 'active_model/serializer'

module Spree
  module Wombat
    module Jirafe

      class TaxonSerializer < ActiveModel::Serializer

        attributes :id, :parent_id, :position, :name, :permalink, :taxonomy_id,
          :description, :created_at, :updated_at

        def created_at
          object.created_at.getutc.try(:iso8601)
        end

        def updated_at
          object.updated_at.getutc.try(:iso8601)
        end

      end

    end
  end
end
