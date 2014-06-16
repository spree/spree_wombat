module Spree
  ProductProperty.class_eval do
    belongs_to :product, :touch => true
  end
end
