# frozen_string_literal: true

require_relative "handler"
require "delfos/call_stack"

module Delfos
  class MethodTrace
    class ReturnHandler < Handler
      def perform
        return unless relevant?

        begin
          CallStack.pop
        rescue
          nil
        end
      end
    end
  end
end
