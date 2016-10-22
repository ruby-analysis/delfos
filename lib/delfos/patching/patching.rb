# frozen_string_literal: true
require "pry"
require 'pry-nav'

require_relative "added_methods"

module Delfos
  class Patching
    class << self
      def perform(klass, name, private_methods, class_method:)
        new(klass, name, private_methods, class_method).setup
      end

      def notify_inheritance(klass, sub_klass)
        AddedMethods.set_sub_klass(klass, sub_klass)
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
      method_selector = method_selector()

      method_defining_method.call(name) do |*args, **keyword_args, &block|
        method_to_call = method_selector.call(self, class_method, original)


        MethodLogging.log(self, args, keyword_args, block, class_method, caller.dup, binding.dup, method_to_call)

        result = performer.call(method_to_call, args, keyword_args, block)
        ExecutionChain.pop
        result
      end
    end


    private

    def method_selector
      lambda do |instance, class_method, original|
        if class_method
          if original.receiver == instance
            original
          else
            AddedMethods.fetch_class_method(original, instance.to_s)
          end
        else
          original.bind(instance)
        end
      end
    end

    def perform_call(method_to_call, args, keyword_args, block)
      if keyword_args.empty?
        method_to_call.call(*args, &block)
      else
        method_to_call.call(*args, **keyword_args, &block)
      end
    end

    def original_method
      @original_method ||= if class_method
                             klass.method(name)
                           else
                             klass.instance_method(name)
                           end
    end

    def method_defining_method
      class_method ? klass.method(:define_singleton_method) : klass.method(:define_method)
    end

    def ensure_method_recorded!
      return true if bail?

      AddedMethods.append(klass, key, original_method)

      false
    end

    def bail?
      method_has_been_added? || private_method? || exclude?
    end

    def method_has_been_added?
      AddedMethods.added?(klass, key)
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
