require 'active_model/serializer'

module Spree
  module Wombat
    module Jirafe

      class ProductWithoutVariantsSerializer < Wombat::ProductSerializer

        attributes :meta_data

        def meta_data
          {
            :jirafe => ActiveModel::ArraySerializer.new(object.taxons,
              each_serializer: Spree::Wombat::Jirafe::TaxonSerializer,
              root: "taxons"
            )
          }
        end
      end

    end
  end
end
