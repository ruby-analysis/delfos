# frozen_string_literal: true

require "delfos/method_logging"
require "delfos/call_stack"

require_relative "module_defining_methods"
require_relative "unstubber"
require_relative "parameter_extraction"
require_relative "method_definition"

module Delfos
  module Patching
    MUTEX = Mutex.new

    class MethodOverride
      include ModuleDefiningMethods

      class << self
        def setup(klass, name, class_method:)
          return if skip_meta_programming_defined_method?

          MUTEX.synchronize do
            return if Thread.current[:__delfos_disable_patching]
          end

          instance = new(klass, name, class_method)

          instance.ensure_method_recorded_once!
        end

        META_PROGRAMMING_REGEX = /`define_method'\z|`attr_accessor'\z|`attr_reader'\z|`attr_writer'\z/

        private

        def skip_meta_programming_defined_method?
          return unless meta_programmed_method_stack_frame(caller.dup)

          Delfos.logger.debug {"Skipping setting up delfos logging of method defined by #{result} #{stack[i+1]}"}
          true
        end

        def patching_index(stack)
          stack.index { |l| l["delfos/patching/basic_object.rb"] }
        end

        def meta_programmed_method_stack_frame(stack)
          i = patching_index(stack)
          return unless i

          stack[i + 1][META_PROGRAMMING_REGEX]
        end
      end

      attr_reader :klass, :name, :class_method

      def initialize(klass, name, class_method)
        @klass           = klass
        @name            = name
        @class_method    = class_method
        original_method # ensure memoized method is the original not the overridden one
      end

      def ensure_method_recorded_once!
        record_method! { setup }
      end

      # Redefine the method at runtime to enabling logging to Neo4j
      def setup
        method_string, file, line_number = method_definition()

        mod = module_definition(klass, name, class_method) do
          module_eval method_string, file, line_number
        end

        receiver = class_method ? klass.singleton_class : klass
        receiver.prepend mod
      end

      def method_definition
        MethodDefinition.new(name, class_method, parameters).setup
      end

      def parameters
        ParameterExtraction.new(original_method).parameters
      end

      def self.with_stack(call_site)
        return yield unless call_site

        begin
          CallStack.push(call_site)
          yield
        ensure
          CallStack.pop
        end
      end

      def original_method
        @original_method ||= klass.send(method_finding_method, name)
      end

      private

      def method_finding_method
        class_method ? :method : :instance_method
      end

      def record_method!
        return true if ::Delfos::MethodLogging.exclude?(original_method)
        MethodCache.append(klass: klass, method: original_method)

        yield
      end
    end
  end
end
