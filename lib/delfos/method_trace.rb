require_relative "method_trace/return_handler"
require_relative "method_trace/call_handler"
require_relative "method_trace/raise_handler"

module Delfos
  class MethodTrace
    ALL_ERRORS = {}

    class << self
      def trace
        on_call.enable
        on_return.enable
        on_raise.enable
      end

      def disable!
        @on_call&.disable
        @on_call = nil

        @on_return&.disable
        @on_return = nil

        @on_raise&.disable
        @on_raise = nil
      end

      def on_call
        @on_call ||= setup_trace_point(:call, CallHandler)
      end

      def on_return
        @on_return ||= setup_trace_point(:return, ReturnHandler)
      end

      def on_raise
        @on_raise ||= setup_trace_point(:raise, RaiseHandler)
      end

      private

      def setup_trace_point(type, klass)
        TracePoint.new(type) do |tp|
          next unless AppDirectories.include_files?(tp.path)
          klass.new(tp).perform
        end
      end
    end
  end
end
