# frozen_string_literal: true

require_relative "method_trace/call_handler"
require_relative "call_stack"

module Delfos
  module MethodTrace
    class << self
      def enable!
        method_trace.perform
      end

      def disable!
        @method_trace&.disable!
        @method_trace = nil
      end

      private

      def method_trace
        @method_trace ||= Setup.new
      end
    end

    class Setup
      def perform
        on_call.enable
        on_return.enable
        @last_returned = nil
      end

      def disable!
        @on_call&.disable
        @on_return&.disable
      end

      def on_call
        @on_call ||= setup_trace_point(:call) do |tp|
          CallHandler.new(tp).perform
        end
      end

      def on_return
        @on_return ||= setup_trace_point(:return) do |tp|
          next if check_for_bug!(tp)

          CallStack.pop

          @last_returned = tp
        end
      end

      private

      # FIXME: There seems to be a bug where the last TracePoint in a chain
      # when returning to (main) is duplicated. Can't get to the source of
      # this.  But the only effect seems to be popping the stacking beyond the
      # end so this is a workaround
      def check_for_bug!(tp)
        (@last_returned == tp) && CallStack.height.zero?
      end

      def setup_trace_point(type)
        TracePoint.new(type) do |tp|
          next unless Delfos.include_file?(tp.path)
          yield tp
        end
      end
    end
  end
end
