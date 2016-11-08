# frozen_string_literal: true

require_relative "../method_logging"

module Delfos
  module Patching
    class MethodOverride
      class << self
        def setup(klass, name, private_methods, class_method:)
          instance = new(klass, name, private_methods, class_method)
          return if instance.ensure_method_recorded!
          instance.setup
        end
      end

      attr_reader :klass, :name, :private_methods, :class_method

      def initialize(klass, name, private_methods, class_method)
        @klass = klass
        @name = name
        @private_methods = private_methods
        @class_method = class_method
      end

      # Redefine the method (only once) at runtime to enabling logging to Neo4j
      def setup
        cm, performer, method_selector = class_method(), method(:perform_call), method(:method_selector)

        method_defining_method.call(name) do |*args, **kw_args, &block|
          method_to_call = method_selector.call(self)

          Delfos.method_logging.log(self, args, kw_args, block, cm,
                                    caller.dup, binding.dup, method_to_call)

          performer.call(method_to_call, args, kw_args, block).tap do
            ExecutionChain.pop
          end
        end
      end

      def original_method
        @original_method ||= if class_method
                               klass.method(name)
                             else
                               klass.instance_method(name)
                             end
      end

      def ensure_method_recorded!
        return true if bail?

        Delfos::MethodLogging::AddedMethods.append(klass, key, original_method)

        false
      end


      private

      def method_selector(instance)
        if class_method
          m = Delfos::MethodLogging::AddedMethods.find(instance, "ClassMethod_#{name}")
          m.receiver == instance ? m : m.unbind.bind(instance)
        else
          original_method.bind(instance)
        end
      end

      def perform_call(method_to_call, args, keyword_args, block)
        if keyword_args.empty?
          method_to_call.call(*args, &block)
        else
          method_to_call.call(*args, **keyword_args, &block)
        end
      end

      def method_defining_method
        class_method ? klass.method(:define_singleton_method) : klass.method(:define_method)
      end

      def bail?
        method_has_been_added? || private_method? || exclude?
      end

      def method_has_been_added?
        Delfos::MethodLogging::AddedMethods.find(klass, key)
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
