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
        parameters = ParameterExtraction.new(om).parameters

        mod = module_definition(klass, name, class_method) do
          method_string, file, line = [<<-METHOD, __FILE__, __LINE__ + 1]
            def #{method_name}(#{parameters})
              parameters = Delfos::MethodLogging::MethodParameters.new(#{parameters})

              call_site = Delfos::MethodLogging::CallSiteParsing.new(caller.dup).perform

              if call_site
                klass = self.is_a?(Module) ? self : self.class
                om = MethodCache.find(klass: klass, class_method: #{cm}, method_name: #{method_name.inspect})

                if om
                  Delfos::MethodLogging.log(call_site, self, om, #{cm}, parameters)
                else
                  Delfos.logger.error("Method not found for \#{klass}, class_method: #{cm}, method_name: #{method_name}")
                end
              end

              MethodOverride.with_stack(call_site) do
                super(#{parameters})
              end
            end
          METHOD

          begin
            module_eval method_string, file, line
          rescue SyntaxError
            byebug
          end
        end
        return unless mod

        if class_method
          klass.singleton_class.prepend mod
        else
          klass.prepend mod
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
