module Spree
  Payment.class_eval do
    belongs_to :order, :touch => true
  end
end
