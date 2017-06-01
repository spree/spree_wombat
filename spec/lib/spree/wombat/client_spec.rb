require 'spec_helper'

module Spree
  module Wombat
    describe Client do
      # subject do
      #   Client.new()
      # end

      let(:params) { { api_key: 'key', api_token: 'token' } }
      let(:object) { Spree::Order.create() }

      it '.push_object' do
        allow(Client).to receive(:push)
        expect(Client.push_object(object, params)).not_to raise_error
      end
    end
  end
end
