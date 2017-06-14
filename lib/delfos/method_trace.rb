# frozen_string_literal: true
require_relative "method_trace/call_handler"
require_relative "call_stack"

module Delfos
  module MethodTrace
    class << self
      def trace!
        on_call.enable
        on_return.enable
      end

      def disable!
        @on_call&.disable
        @on_call = nil

        @on_return&.disable
        @on_return = nil
      end

      def on_call
        @on_call ||= setup_trace_point(:call) do |tp|
          CallHandler.new(tp).perform
        end
      end

      def on_return
        @on_return ||= setup_trace_point(:return) do |tp|
          CallStack.pop
        end
      end

      private

      def setup_trace_point(type)
        TracePoint.new(type) do |tp|
          next unless Delfos.include_file?(tp.path)

          yield tp
        end
      end
    end
  end
end
