require "spec_helper"

module Spree
  module Wombat
    describe ResponderSerializer do

      let(:responder) {Responder.new("12355","Order abc124 was added")}

      it "correctly serializes a Hub::Responder" do
        json_response = "{\"request_id\":\"12355\",\"summary\":\"Order abc124 was added\"}"
        expect(ResponderSerializer.new(responder, root: false).to_json).to eql json_response
      end

      it "serializes a backtrace when present" do
        responder.exception = StandardError.new
        responder.exception.set_backtrace(['some backtrace'])
        json_response = "{\"request_id\":\"12355\",\"summary\":\"Order abc124 was added\",\"backtrace\":\"[\\\"some backtrace\\\"]\"}"
        expect(ResponderSerializer.new(responder, root: false).to_json).to eql json_response
      end

      it "serializes objects when present" do
        json_response = "{\"request_id\":\"12355\",\"summary\":\"Order abc124 was added\",\"products\":[{\"id\":\"abc\",\"name\":\"Epic awesome tiger pyjamas\"}],\"ninjas\":[{\"id\":1,\"stars\":\"steel\"},{\"id\":2,\"stars\":\"iron\"}]}"
        responder.objects = { products: [{id: "abc", name: "Epic awesome tiger pyjamas"}], ninjas: [{id: 1, stars: "steel"}, { id: 2, stars: "iron"}] }
        expect(ResponderSerializer.new(responder, root: false).to_json).to eql json_response
      end

      it "will not serialize objects when it's nil" do
        json_response = "{\"request_id\":\"12355\",\"summary\":\"Order abc124 was added\"}"
        expect(ResponderSerializer.new(responder, root: false).to_json).to eql json_response
      end
    end
  end
end
