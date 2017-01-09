# frozen_string_literal: true

require "delfos/method_logging"
require "delfos/call_stack"

require_relative "module_defining_methods"
require_relative "unstubber"
require_relative "parameter_extraction"

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
        method_name = name
        om = original_method

        mod = module_definition(klass, name, class_method) do
          parameters = ParameterExtraction.new(om).parameters

          module_eval <<-METHOD
            def #{method_name}(#{parameters})
              stack = caller.dup
              caller_binding = binding.dup
              parameters = Delfos::MethodLogging::MethodParameters.new(#{parameters})

              call_site = Delfos::MethodLogging::CodeLocation.from_call_site(stack, caller_binding)

              if call_site
                class_method = self.is_a?(Class)
                klass = self.is_a?(Class) ? self : self.class
                om = MethodCache.find(klass: klass, class_method: class_method, method_name: __method__)
                Delfos::MethodLogging.log(call_site, self, om, class_method, parameters)
              end

              MethodOverride.with_stack(call_site) do
                begin
                  super(#{parameters})
                rescue Exception => e
                  byebug
                end
              end
            end
          METHOD
        end
        return unless mod

        if class_method
          klass.prepend mod
        else
          klass.instance_eval { prepend mod }
        end
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
