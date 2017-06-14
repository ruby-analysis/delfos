# frozen_string_literal: true

require_relative "handler"
require "delfos/call_stack"

module Delfos
  module MethodTrace
    class CallHandler < Handler
      def perform
        return unless relevant?

        CallStack.push(call_site)

        Delfos.call_site_logger.log(call_site)
      end
    end
  end
end
