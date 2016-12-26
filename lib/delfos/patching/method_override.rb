# frozen_string_literal: true

require "delfos/method_logging"
require "delfos/call_stack"

require_relative "method_calling_exception"
require_relative "method_arguments"
require_relative "module_defining_methods"
require_relative "unstubber"

module Delfos
  module Patching
    MUTEX = Mutex.new

    class MethodOverride
      include ModuleDefiningMethods

      class << self
        def setup(klass, name, private_methods, class_method:)
          MUTEX.synchronize do
            return if Thread.current[:__delfos_disable_patching]
          end

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

      # Redefine the method at runtime to enabling logging to Neo4j
      def setup
        cm = class_method
        with_stack = method(:with_stack)
        method_name = name()
        om = original_method()

        m = module_definition do |m|
          m.class_eval do
            define_method(method_name) do |*args, **kw_args, &block|
              stack, caller_binding = caller.dup, binding.dup
              should_wrap_exceptions = true
              arguments = MethodArguments.new(args, kw_args, block, should_wrap_exceptions)

              call_site = Delfos::MethodLogging::CodeLocation.from_call_site(stack, caller_binding)

              if call_site
                Delfos::MethodLogging.log(call_site, self, om, cm, arguments)
              end

              with_stack.call(call_site) do
                begin
                  if kw_args.length > 0
                    super(*args, **kw_args, &block)
                  else
                    super(*args, &block)
                  end
                rescue TypeError => e
                  byebug
                end
              end
            end
          end
        end
        return unless m

        if class_method
          klass.prepend m
        else
          klass.instance_eval { prepend m }
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
        MethodCache.append(klass, key, *original_method.source_location)

        yield
      end

      def method_selector(instance)
        if class_method
          m = MethodCache.find(instance, "ClassMethod_#{name}")
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
        MethodCache.find(klass, key)
      end

      def private_method?
        private_methods.include?(name.to_sym)
      end

      def exclude?
        ::Delfos::MethodLogging.exclude?(original_method)
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
