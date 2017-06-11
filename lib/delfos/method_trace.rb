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
        @on_call ||= TracePoint.new(:call) do |tp|
          next unless AppDirectories.include_files?(tp.path)
          CallHandler.new(tp).perform
        end
      end

      def on_return
        @on_return ||= TracePoint.new(:return) do |tp|
          next unless AppDirectories.include_files?(tp.path)
          ReturnHandler.new(tp).perform
        end
      end

      def on_raise
        @on_raise ||= TracePoint.new(:raise) do |tp|
          next unless AppDirectories.include_files?(tp.path)
          RaiseHandler.new(tp).perform
        end
      end
    end
  end
end
