require 'spec_helper'

module Spree
  describe Wombat::WebhookController do

    let!(:message) {
      ::Hub::Samples::Order.request
    }

    let(:parameters) {
      { body: message.to_json, use_route: :spree, format: :json, path: 'my_custom'}
    }

    before do
      ActionController::TestRequest.any_instance.stub(:body) { StringIO.new(message.to_json) }
    end

    context '#consume' do
      context 'with unauthorized request' do
        it 'returns 401 status' do
          post 'consume', parameters
          expect(response.code).to eql "401"
          response_json = ::JSON.parse(response.body)
          expect(response_json["request_id"]).to_not be_nil
          expect(response_json["summary"]).to eql "Unauthorized!"
        end
      end

      context 'with the correct auth' do
        before do
          request.env['HTTP_X_HUB_TOKEN'] = 'abc1233'
        end

        context 'and an existing handler for the webhook' do
          it 'will process the webhook handler' do
            post 'consume', parameters
            expect(response).to be_success
          end
        end

        context 'when an exception happens' do
          it 'will return resonse with the exception message and backtrace' do
            parameters = { body: message, path: 'upblate_order', content_type: 'application/json', use_route: :spree, format: :json }
            post 'consume', parameters
            expect(response.code).to eql "500"
            json = JSON.parse(response.body)
            expect(json["summary"]).to eql "uninitialized constant Spree::Wombat::Handler::UpblateOrderHandler"
            expect(json["backtrace"]).to be_present
          end
        end

      end
    end
  end
end
