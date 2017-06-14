# frozen_string_literal: true

require_relative "handler"
require "delfos/call_stack"

module Delfos
  module MethodTrace
    class RaiseHandler < Handler
      def perform
        return unless relevant?
        # TODO: - how to determine if this is an unhandled exception ? so should pop_until_top
        # CallStack.pop_until_top
      end
    end
  end
end
