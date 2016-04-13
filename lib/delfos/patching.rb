# frozen_string_literal: true
module Delfos
  class Patching
    class << self
      def perform(klass, name, private_methods, class_method:)
        new(klass, name, private_methods, class_method).setup
      end

      def added_methods
        @added_methods ||= {}
      end

      def method_definition_for(klass, key)
        # Find method definitions defined in klass or its ancestors
        super_klass = klass.ancestors.detect do |k|
          added_methods[k.to_s]
        end

        klass_hash = added_methods[super_klass.to_s] || {}
        klass_hash[key]
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
      return if ensure_method_recorded!
      original = original_method
      class_method = class_method()
      performer = method(:perform_call)

      method_defining_method.call(name) do |*args, **keyword_args, &block|
        MethodLogging.log(self, args, keyword_args, block, class_method, caller.dup, binding.dup, original)

        method_to_call = class_method ? original : original.bind(self)
        result = performer.call(method_to_call, args, keyword_args, block)
        Delfos::ExecutionChain.pop
        result
      end
    end


    private

    def perform_call(method_to_call, args, keyword_args, block)
      if keyword_args.empty?
        method_to_call.call(*args, &block)
      else
        method_to_call.call(*args, **keyword_args, &block)
      end
    end

    def original_method
      @original_method ||= class_method ? klass.singleton_method(name) : klass.instance_method(name)
    end

    def method_defining_method
      class_method ? klass.method(:define_singleton_method) : klass.method(:define_method)
    end

    def ensure_method_recorded!
      return true if bail?

      self.class.added_methods[klass.to_s] ||= {}
      self.class.added_methods[klass.to_s][key] = original_method.source_location

      false
    end

    def bail?
      method_has_been_added? || private_method? || exclude?
    end

    def method_has_been_added?
      return false unless self.class.added_methods[self]
      return false unless self.class.added_methods[self][klass]

      self.class.added_methods[klass][key]
    end

    def private_method?
      private_methods.include?(name.to_sym)
    end

    def exclude?
      ::Delfos::MethodLogging.exclude_from_logging?(original_method)
    end

    def key
      "#{type}_#{name}"
    end

    def type
      class_method ? "ClassMethod" : "InstanceMethod"
    end
  end
end
