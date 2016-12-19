# frozen_string_literal: true

require "delfos/method_logging"
require "delfos/call_stack"

require_relative "method_calling_exception"
require_relative "method_arguments"

module Delfos
  module Patching
    MUTEX = Mutex.new

    #containers for the individual modules created to log each method call
    module ClassMethodLogging
    end

    module InstanceMethodLogging
    end

    class MethodOverride
      class << self
        def setup(klass, name, private_methods, class_method:)
          MUTEX.synchronize do
            return if Thread.current[:__delfos_disable_patching]
          end

            instance = new(klass, name, private_methods, class_method)

            instance.ensure_method_recorded_once!
        end

        def unsetup(klass, name, private_methods, class_method:)
          instance = new(klass, name, private_methods, class_method)

          instance.unsetup
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

      def unsetup
        method_name = name()
        meth = method_defining_method

        module_definition.instance_eval do
          begin
            remove_method :"#{method_name}" 
          rescue NameError => e
            raise unless e.message["method `#{method_name}' not defined in"]
          end
        end

      end
      # Redefine the method (only once) at runtime to enabling logging to Neo4j
      def setup
        cm = class_method
        with_stack = method(:with_stack)
        method_name = name()
        om = original_method()

        if class_method
          m = module_definition.class_eval do
            define_singleton_method(method_name) do |*args, **kw_args, &block|
              stack, caller_binding = caller.dup, binding.dup
              should_wrap_exceptions = true
              arguments = MethodArguments.new(args, kw_args, block, should_wrap_exceptions)

              call_site = Delfos::MethodLogging::CodeLocation.from_call_site(stack, caller_binding)

              if call_site
                Delfos.method_logging.log(call_site, self, om, cm, arguments)
              end

              with_stack(call_site) do
                if kw_args.empty?
                  super(*args, &block)
                else
                  super(*args, **kw_args, &block)
                end

              end
            end

            self
          end

          klass.instance_eval{prepend m}
        else
          m = module_definition.class_eval do
            define_method(method_name) do |*args, **kw_args, &block|
              stack, caller_binding = caller.dup, binding.dup
              should_wrap_exceptions = true
              arguments = MethodArguments.new(args, kw_args, block, should_wrap_exceptions)

              call_site = Delfos::MethodLogging::CodeLocation.from_call_site(stack, caller_binding)

              if call_site
                Delfos.method_logging.log(call_site, self, om, cm, arguments)
              end

              with_stack.call(call_site) do
                if kw_args.empty?
                  super(*args, &block)
                else
                  super(*args, **kw_args, &block)
                end
              end
            end

            self
          end

          klass.prepend m
        end
      end

      def module_definition
        if class_method
          eval <<-RUBY
            module ClassMethodLogging
             #{nesting klass.name , <<-CODE
                module #{camelize(name.to_s)}
                end
              CODE
             }
            end
          RUBY

          eval "ClassMethodLogging::#{klass.name}::#{camelize(name.to_s)}"
        else
          eval <<-RUBY
            module InstanceMethodLogging
             #{nesting klass.name , <<-CODE
                module #{camelize(name.to_s)}
                end
              CODE
             }
            end
          RUBY

          eval "InstanceMethodLogging::#{klass.name}::#{camelize(name.to_s)}"
        end
      end

      def nesting(n, code)
        add_namespace = lambda do |ns, code|
          "module #{ns}\n#{code}\nend"
        end

        n.split("::").reverse.each do |ns|
          code = add_namespace.call(ns, code)
        end

        code
      end

      def camelize(string, uppercase_first_letter = true)
        string = string.sub(/^[a-z\d]*/) { $&.capitalize }

        string.gsub(/(?:_|(\/))([a-z\d]*)/) { "#{$1}#{$2.capitalize}" }.gsub('/', '::')
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

        MethodCache.append(klass, key, original_method)
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
