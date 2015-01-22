require 'spec_helper'

module Spree
  module Wombat
    describe PromotionSerializer, type: :serializer do
      let(:promotion) { Spree::Promotion.new(name: "Promo", code: "pro") }
      let(:serialized) { JSON.parse(PromotionSerializer.new(promotion, root: false).to_json) }

      before { promotion.build_promotion_category(name: "Category", code: "cat") }

      it { expect(serialized['code']).to eq 'pro' }
      it { expect(serialized['name']).to eq 'Promo' }
      it { expect(serialized['category_code']).to eq 'cat' }
      it { expect(serialized['category_name']).to eq 'Category' }

    end
  end
end
