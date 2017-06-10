require_relative "handler"
require "delfos/call_stack"

module Delfos
  class MethodTrace
    class RaiseHandler < Handler
      def perform
        return unless relevant?


      end
    end
  end
end
