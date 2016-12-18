# frozen_string_literal: true

require_relative "../method_logging"
require_relative "method_calling_exception"
require_relative "method_arguments"

module Delfos
  module Patching
    class MethodOverride
      class << self
        def setup(klass, name, private_methods, class_method:)
          instance = new(klass, name, private_methods, class_method)

          instance.ensure_method_recorded_once!
        end
      end

      attr_reader :klass, :name, :private_methods, :class_method

      def initialize(klass, name, private_methods, class_method)
        @klass           = klass
        @name            = name
        @private_methods = private_methods
        @class_method    = class_method
        original_method # ensure memoized method is the original not the overridden one
      end

      def ensure_method_recorded_once!
        record_method! { setup }
      end

      # Redefine the method (only once) at runtime to enabling logging to Neo4j
      def setup
        processor = method(:process)
        cm = class_method

        method_defining_method.call(name) do |*args, **kw_args, &block|
          arguments = MethodArguments.new(args, kw_args, block)

          processor.call(self, caller.dup, binding.dup, arguments, cm)
        end
      end

      def process(instance, stack, caller_binding, arguments, class_method)
        method_to_call = method_selector(instance)

        call_site = Delfos::MethodLogging::CodeLocation.from_call_site(stack, caller_binding)

        with_logging(call_site, instance, method_to_call, class_method, arguments) do
          arguments.apply_to(method_to_call)
        end
      end

      def with_logging(call_site, instance, method_to_call, class_method, arguments)
        Delfos.method_logging.log(call_site, instance, method_to_call, class_method, arguments) if call_site

        with_stack(call_site) do
          yield
        end
      end

      def with_stack(call_site)
        return yield unless call_site

        begin
          CallStack.push(call_site)
          yield
        ensure
          CallStack.pop
        end
      end

      def original_method
        @original_method ||= if class_method
                               klass.method(name)
                             else
                               klass.instance_method(name)
                             end
      end

      private

      def record_method!
        return true if bail?
        yield

        MethodLogging::MethodCache.append(klass, key, original_method)
      end

      def method_selector(instance)
        if class_method
          m = MethodLogging::MethodCache.find(instance, "ClassMethod_#{name}")
          m.receiver == instance ? m : m.unbind.bind(instance)
        else
          original_method.bind(instance)
        end
      end

      def method_defining_method
        class_method ? klass.method(:define_singleton_method) : klass.method(:define_method)
      end

      def bail?
        method_has_been_added? || private_method? || exclude?
      end

      def method_has_been_added?
        MethodLogging::MethodCache.find(klass, key)
      end

      def private_method?
        private_methods.include?(name.to_sym)
      end

      def exclude?
        ::Delfos.method_logging.exclude?(original_method)
      end

      def key
        "#{type}_#{name}"
      end

      def type
        class_method ? "ClassMethod" : "InstanceMethod"
      end
    end
  end
end
