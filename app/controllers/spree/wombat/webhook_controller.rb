module Spree
  module Wombat
    class WebhookController < ActionController::Base
      # Applications can use error_notifier to forward errors to tools like
      # airbrake, honeybadger, rollbar, etc.
      # This should be an object that responds to `call` and accepts the
      # responder as an argument.
      class_attribute :error_notifier

      before_filter :save_request_data, :authorize
      rescue_from Exception, :with => :exception_handler

      def consume
        handler = Handler::Base.build_handler(@called_hook, @webhook_body)
        responder = handler.process
        render_responder(responder)
      end

      protected
      def authorize
        unless request.headers['HTTP_X_HUB_TOKEN'] == Spree::Wombat::Config[:connection_token]
          base_handler = Handler::Base.new(@webhook_body)
          responder = base_handler.response('Unauthorized!', 401)
          render_responder(responder)
          return false
        end
      end

      def exception_handler(exception)
        base_handler = Handler::Base.new(@webhook_body)
        responder = base_handler.response(exception.message, 500, nil, exception)
        render_responder(responder)
        return false
      end

      def save_request_data
        @called_hook = params[:path]
        @webhook_body = request.body.read
      end

      def render_responder(responder)
        if responder.exception
          logger.error responder.exception
          logger.error responder.exception.backtrace.join("\n").to_s
          if error_notifier
            error_notifier.call(responder)
          end
        end
        if responder.code >= 400
          logger.info "responder_summary=#{responder.summary.inspect}"
        end
        render(
          json: ResponderSerializer.new(responder, root: false),
          status: responder.code
        )
      end
    end
  end
end
