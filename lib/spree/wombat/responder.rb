require "active_model/serializer_support"

module Spree
  module Wombat
    class Responder
      class ErroredResponse < StandardError; end

      include ActiveModel::SerializerSupport
      attr_accessor :request_id, :summary, :code, :objects, :exception

      def initialize(request_id, summary, code=200, objects=nil, exception=nil)
        if code.to_i.between?(500,599) && exception.nil?
          exception = ErroredResponse.new(summary)
          exception.set_backtrace(caller)
        end

        self.request_id = request_id
        self.summary = summary
        self.code = code
        self.objects = objects
        self.exception = exception
      end

    end
  end
end
