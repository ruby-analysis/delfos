require "binding_of_caller"
require "delfos/code_location/call_site"
require "delfos/code_location/method"
require_relative "call_stack"
require_relative "app_directories"

module Delfos
  class MethodTrace
    ALL_ERRORS = {}

    class << self
      STACK_OFFSET = 5

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
          handle_call(tp)
        end
      end

      def handle_call(tp)
        call_site = call_site_from(tp)
        return unless relevant?(call_site)

        CallStack.push(call_site)

        Delfos.call_site_logger.log(call_site)
      end

      def on_return
        @on_return ||= TracePoint.new(:return) do |tp|
          next unless AppDirectories.include_files?(tp.path)
          handle_return(tp)
        end
      end

      def on_raise
        @on_raise ||= TracePoint.new(:raise) do |tp|
          next unless AppDirectories.include_files?(tp.path)
          #next unless relevant?(tp)
          # TODO - how to determine if this is an unhandled exception ? so should pop_until_top
          # CallStack.pop_until_top
        end
      end

      def handle_return(tp)
        call_site = call_site_from(tp)
        return unless relevant?(call_site)

        CallStack.pop rescue nil
      end

      private

      def relevant?(call_site)
        call_site && AppDirectories.include_files?(
          call_site.raw_path,
          call_site.container_method_path,
          call_site.called_method_path
        )
      end

      def call_site_from(tp)
        CodeLocation::CallSite.new(
          file:        eval_in_caller("__FILE__"),
          line_number: eval_in_caller("__LINE__"),
          container_method: container_method,
          called_method:    called_method(tp),
        )
      end

      RUBY_IS_MAIN                = "self.class == Object && self&.to_s == 'main'"
      RUBY_INSTANCE_METHOD_SOURCE = "self.class.instance_method(__method__).source_location"
      RUBY_CLASS_METHOD_SOURCE    = "method(__method__).source_location"

      def container_method
        object       = eval_in_caller('self', 1)
        class_method = eval_in_caller('is_a?(Module)', 1)
        method_finder = class_method ? RUBY_CLASS_METHOD_SOURCE : RUBY_INSTANCE_METHOD_SOURCE
        file         = eval_in_caller("#{RUBY_IS_MAIN} ? __FILE__ : #{method_finder}.first", 1)
        line         = eval_in_caller("#{RUBY_IS_MAIN} ? 0        : #{method_finder}.last",  1)
        meth         = eval_in_caller("__method__", 1)

        CodeLocation::Method.new(
          object:       object,
          method_name:  meth,
          file:         file,
          line_number:  line,
          class_method: class_method,
        )
      end

      def eval_in_caller(s, extra_offset=0, &block)
        other = binding.of_caller(STACK_OFFSET + extra_offset)

        begin
          other.eval(s)
        rescue Exception => e
          ALL_ERRORS[e.message] = other.receiver
        end
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
