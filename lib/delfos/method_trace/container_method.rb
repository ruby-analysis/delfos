require "delfos/code_location/method"
require "delfos/method_trace/eval_in_caller"

module Delfos
  class MethodTrace
    class ContainerMethod
      include EvalInCaller
      STACK_OFFSET = 8

      def determine
        # ensure evaluated and memoised with correct stack offset
        class_method

        CodeLocation::Method.new(
          object:       object,
          method_name:  meth,
          file:         file,
          line_number:  line,
          class_method: class_method,
        )
      end

      private

      def object
        @object ||= eval_in_caller('self', STACK_OFFSET)
      end

      def class_method
        @class_method ||= eval_in_caller('is_a?(Module)', STACK_OFFSET)
      end

      RUBY_IS_MAIN                = "self.class == Object && self&.to_s == 'main'"
      RUBY_SOURCE_LOCATION        = "(__method__).source_location"
      RUBY_CLASS_METHOD_SOURCE    = "method#{RUBY_SOURCE_LOCATION}"
      RUBY_INSTANCE_METHOD_SOURCE = "self.class.instance_method#{RUBY_SOURCE_LOCATION}"

      def method_finder
        @method_finder ||= class_method ? RUBY_CLASS_METHOD_SOURCE : RUBY_INSTANCE_METHOD_SOURCE
      end

      def file
        @file ||= eval_in_caller("(#{RUBY_IS_MAIN}) ? __FILE__ : (#{method_finder}.first)", STACK_OFFSET)
      end

      def line
        @line ||= eval_in_caller("(#{RUBY_IS_MAIN}) ? 0 : (#{method_finder}.last)", STACK_OFFSET)
      end

      def meth
        @meth ||= eval_in_caller("__method__", STACK_OFFSET)
      end
    end
  end
end
