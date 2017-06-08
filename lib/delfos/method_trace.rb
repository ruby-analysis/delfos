require "binding_of_caller"
require "delfos/code_location/call_site"
require "delfos/code_location/method"
require_relative "call_stack"
require_relative "app_directories"

module Delfos
  class MethodTrace
    class << self
      STACK_OFFSET = 6

      def trace
        on_raise.enable
        on_call.enable
        on_return.enable
      end

      def disable!
        @on_call&.disable
        @on_call = nil

        @on_return&.disable
        @on_return = nil

        @on_raise&.disable
        @on_raise = nil

        @disable_trace_point = nil
      end

      def on_call
        @on_call ||= TracePoint.new(:call) do |tp|
          handle_call(tp)
        end
      end

      def temporarily_disable_trace_point
        return if @disable_trace_point
        @disable_trace_point = true

        yield

        @disable_trace_point = false
      end

      def handle_call(tp)
        temporarily_disable_trace_point do
          call_site = call_site_from(tp)
          return unless relevant?(call_site)

          CallStack.push(call_site)

          Delfos.call_site_logger.log(call_site)
        end
      end

      def on_return
        @on_return ||= TracePoint.new(:return) do |tp|
          handle_return tp
        end
      end

      def handle_return(tp)
        temporarily_disable_trace_point do
          call_site = call_site_from(tp)
          return unless relevant?(call_site)

          CallStack.pop rescue nil
        end
      end

      def on_raise
        @on_raise ||= TracePoint.new(:raise) do |tp|
          temporarily_disable_trace_point do
            #next unless relevant?(tp)
            # TODO - how to determine if this is an unhandled exception ? so should pop_until_top
            # CallStack.pop_until_top
          end
        end
      end

      private

      def relevant?(call_site)
        puts call_site.path
        puts call_site.container_method_path
        puts call_site.called_method_path

        AppDirectories.include_files?(
          call_site.path,
          call_site.container_method_path,
          call_site.called_method_path
        )
      end

      def call_site_from(tp)
        CodeLocation::CallSite.new(
          file:        eval_in_caller("__FILE__"),
          line_number: eval_in_caller("__LINE__"),
          container_method: container_method,
          called_method: called_method(tp),
        )
      end

      def container_method
        CodeLocation::Method.new(
          object:       eval_in_caller('is_a?(Module) ? self : self.class', 1),
          method_name:  eval_in_caller("__method__", 1),
          file:         eval_in_caller("method(__method__).source_location.first", 1),
          line_number:  eval_in_caller("method(__method__).source_location.last", 1),
          class_method: eval_in_caller('is_a?(Module)', 1),
        )
      end

      def eval_in_caller(s, extra_offset=0)
        return if s.nil?

        other = binding.of_caller(STACK_OFFSET + extra_offset)
        other.eval(s)
      end

      def called_method(tp)
        CodeLocation::Method.new(
          object:       tp.self,
          method_name:  tp.method_id,
          file:         tp.path,
          line_number:  tp.lineno,
          class_method: tp.self.is_a?(Module),
        )
      end
    end
  end
end
