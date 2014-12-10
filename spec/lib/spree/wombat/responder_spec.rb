require 'spec_helper'

module Spree
  module Wombat
    describe Responder do

      describe '#initialize' do
        subject do
          Responder.new(*params)
        end

        let(:params) { [request_id, summary, code, objects, exception] }

        let(:request_id) { 'some id' }
        let(:summary) { 'some summary' }
        let(:code) { 200 }
        let(:objects) { nil }
        let(:exception) { nil }

        context 'with a 5xx error code and no exception' do
          let(:code) { 500 }

          it 'builds an exception from the summary' do
            expect(subject.exception).to be_a Responder::ErroredResponse
            expect(subject.exception.message).to eq summary
          end
        end
      end

    end
  end
end
