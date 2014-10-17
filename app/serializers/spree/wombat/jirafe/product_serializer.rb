require 'active_model/serializer'

module Spree
  module Wombat
    module Jirafe

      class ProductSerializer < ProductWithoutVariantsSerializer

        attributes :variants

        def variants
          if object.variants.empty?
            [Spree::Wombat::Jirafe::VariantSerializer.new(object.master, root:false)]
          else
            ActiveModel::ArraySerializer.new(
              object.variants,
              each_serializer: Spree::Wombat::Jirafe::VariantSerializer,
              root: false
            )
          end
        end
      end

    end
  end
end
