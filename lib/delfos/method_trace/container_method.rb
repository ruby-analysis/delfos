require "delfos/code_location/method"
require "delfos/method_trace/eval_in_caller"

module Delfos
  class MethodTrace
    class ContainerMethod
      include EvalInCaller
      STACK_OFFSET = 9

      def determine
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
        eval_in_caller('self', STACK_OFFSET)
      end

      def class_method
        eval_in_caller('is_a?(Module)', STACK_OFFSET)
      end

      RUBY_IS_MAIN                = "self.class == Object && self&.to_s == 'main'"
      RUBY_INSTANCE_METHOD_SOURCE = "self.class.instance_method(__method__).source_location"
      RUBY_CLASS_METHOD_SOURCE    = "method(__method__).source_location"

      def method_finder
        class_method ? RUBY_CLASS_METHOD_SOURCE : RUBY_INSTANCE_METHOD_SOURCE
      end

      def file
        ruby = "#{RUBY_IS_MAIN} ? __FILE__ : #{method_finder}.first"

        begin
          eval_in_caller(ruby, STACK_OFFSET)
        rescue Exception => e
          puts "<" * 80
          puts e.message
          puts method_finder
          puts eval_in_caller(method_finder    ,                           STACK_OFFSET ).inspect

          puts ">" * 80
        end
      end

      def line
        eval_in_caller("#{RUBY_IS_MAIN} ? 0 : #{method_finder}.last",  STACK_OFFSET)
      end

      def meth
        eval_in_caller("__method__", STACK_OFFSET)
      end
    end
  end
end
