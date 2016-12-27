# frozen_string_literal: true

require "delfos/method_logging"
require "delfos/call_stack"

require_relative "module_defining_methods"
require_relative "unstubber"

module Delfos
  module Patching
    MUTEX = Mutex.new

    class MethodOverride
      include ModuleDefiningMethods

      class << self
        def setup(klass, name, private_methods, class_method:)
          return if skip_meta_programming_defined_method?

          MUTEX.synchronize do
            return if Thread.current[:__delfos_disable_patching]
          end

          instance = new(klass, name, private_methods, class_method)

          instance.ensure_method_recorded_once!
        end

        META_PROGRAMMING_REGEX = /`define_method'\z|`attr_accessor'\z|`attr_reader'\z|`attr_writer'\z/

        def skip_meta_programming_defined_method?
          stack = caller.dup

          i = stack.index do |l|
            l["delfos/patching/basic_object.rb"]
          end

          return unless i

          result = stack[i + 1][META_PROGRAMMING_REGEX]

          return unless result

          Delfos.logger.debug "Skipping setting up delfos logging of method defined by #{result} #{stack[i+1]}"
          true
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
        method_name = name
        om = original_method

        mod = module_definition(klass, name, class_method) do
          define_method(method_name) do |*args, **kw_args, &block|
            stack = caller.dup
            caller_binding = binding.dup
            parameters = Delfos::MethodLogging::MethodParameters.new(args, kw_args, block)

            call_site = Delfos::MethodLogging::CodeLocation.from_call_site(stack, caller_binding)

            if call_site
              Delfos::MethodLogging.log(call_site, self, om, cm, parameters)
            end

            with_stack.call(call_site) do
              if !kw_args.empty?
                super(*args, **kw_args, &block)
              else
                super(*args, &block)
              end
            end
          end
        end
        return unless mod

        if class_method
          klass.prepend mod
        else
          klass.instance_eval { prepend mod }
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
        MethodCache.append(klass: klass, method: original_method)

        yield
      end

      def bail?
        method_has_been_added? || private_method? || exclude?
      end

      def method_has_been_added?
        MethodCache.find(klass: klass, class_method: class_method, method_name: name)
      end

      def private_method?
        private_methods.include?(name.to_sym)
      end

      def exclude?
        ::Delfos::MethodLogging.exclude?(original_method)
      end
    end
  end
end
