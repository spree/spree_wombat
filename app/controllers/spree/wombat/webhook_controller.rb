module Spree
  module Wombat
    class WebhookController < ActionController::Base
      before_filter :save_request_data, :authorize
      rescue_from Exception, :with => :exception_handler

      def consume
        handler = Handler::Base.build_handler(@called_hook, @webhook_body)
        responder = handler.process
        render json: responder, root: false, status: responder.code
        #render json: ResponderSerializer.new(responder, root: false), status: responder.code
      end

      protected
      def authorize
        unless request.headers['HTTP_X_HUB_TOKEN'] == Spree::Wombat::Config[:connection_token]
          base_handler = Handler::Base.new(@webhook_body)
          responder = base_handler.response('Unauthorized!', 401)
          render json: responder, root: false, status: responder.code
          return false
        end
      end

      def exception_handler(exception)
        base_handler = Handler::Base.new(@webhook_body)
        logger.error exception
        logger.error exception.backtrace.join("\n").to_s
        responder = base_handler.response(exception.message, 500)
        responder.backtrace = exception.backtrace.to_s
        render json: responder, root: false, status: responder.code
        return false
      end

      def save_request_data
        @called_hook = params[:path]
        @webhook_body = request.body.read
      end

    end
  end
end
