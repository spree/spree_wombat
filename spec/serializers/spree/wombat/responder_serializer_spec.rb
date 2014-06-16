require "spec_helper"

module Spree
  module Wombat
    describe ResponderSerializer do

      let(:responder) {Responder.new("12355","Order abc124 was added")}

      it "correctly serializes a Wombat::Responder" do
        json_response = "{\"request_id\":\"12355\",\"summary\":\"Order abc124 was added\"}"
        expect(ResponderSerializer.new(responder, root: false).to_json).to eql json_response
      end

      it "serializes a backtrace when present" do
        responder.backtrace = "Big fat error"
        json_response = "{\"request_id\":\"12355\",\"summary\":\"Order abc124 was added\",\"backtrace\":\"Big fat error\"}"
        expect(ResponderSerializer.new(responder, root: false).to_json).to eql json_response
      end

      it "serializes objects when present" do
        json_response = "{\"request_id\":\"12355\",\"summary\":\"Order abc124 was added\",\"objects\":{\"products\":{\"id\":\"abc\",\"name\":\"Epic awesome tiger pyjamas\"}}}"
        responder.objects = { products: {id: "abc", name: "Epic awesome tiger pyjamas"} }
        expect(ResponderSerializer.new(responder, root: false).to_json).to eql json_response
      end

    end
  end
end
