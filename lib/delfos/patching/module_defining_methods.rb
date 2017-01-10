# frozen_string_literal: true
module Delfos
  module Patching
    # containers for the individual modules created to log each method call
    module ClassMethodLogging
    end

    module InstanceMethodLogging
    end

    module ModuleDefiningMethods
      def module_definition(klass, method_name, class_method, &block)
        definer = ModuleDefiner.new(klass, method_name, class_method)

        if block_given?
          definer.perform(&block) 
        else
          definer.perform
        end
      end
    end

    class ModuleDefiner
      attr_reader :klass, :method_name, :class_method

      def initialize(klass, method_name, class_method)
        @klass, @method_name, @class_method = klass, method_name, class_method
      end

      def perform(&block)
        that = self

        Patching.const_get(module_type).instance_eval do
          namespace = that.find_or_create(self, that.safe_class_name)

          m = that.find_or_create(namespace, that.safe_method_name)

          m.class_eval(&block) if block_given?

          m
        end
      end

      def module_type 
        class_method ? "ClassMethodLogging" : "InstanceMethodLogging"
      end

      def safe_class_name
        module_safe_name(klass.name || klass.to_s)
      end

      def safe_method_name
        module_safe_name(method_name.to_s)
      end

      def find_or_create(container, module_name)
        module_name = module_name.tr(":", "_")

        result = container.const_get(module_name)

        # E.g. finding `::A' instead of Delfos::Patching::InstanceMethodLogging::A
        if result == klass || result.name[module_name] == result.name
          create(container, module_name)
        else
          result
        end
      rescue NameError => e
        raise unless e.message[module_name]
        create(container, module_name)
      end

      private

      def create(container, module_name)
        m = Module.new

        container.const_set(module_name, m)

        m
      end

      CAPITALIZE_REGEX =/^[a-z\d]*/
      CAMELIZE_REGEX = /(?:_|(\/))([a-z\d]*)/
      ANONYMOUS_CLASS_REGEX = /\#\<Class\:0x(.*)\>/

      def module_safe_name(string, _uppercase_first_letter = true)
        string = string.sub(CAPITALIZE_REGEX) { $&.capitalize }

        string = string.
          gsub(CAMELIZE_REGEX) { "#{Regexp.last_match(1)}#{Regexp.last_match(2).capitalize}" }.
          gsub(ANONYMOUS_CLASS_REGEX) { "AnonymousClass_#{Regexp.last_match(1)}" }

        MAPPINGS.each do |regex, replacement|
          string = string.gsub(regex, replacement)
        end

        string
      end

      MAPPINGS = [
        ["/", "::"],
        [/\=/, "Equals"],
        [/\<\=\>/, "Spaceship"],
        [/\<\=/, "LessThanOrEqualTo"],
        [/\>\=/, "GreaterThanOrEqualTo"],
        [/\>/, "GreaterThan"],
        [/\</, "LessThan"],
        [/!\~/, "NotMatchOperator"],
        [/\~/, "MatchOperator"],
        [/\?/, "QuestionMark"],
        [/\!$/, "Bang"],
        [/\+/, "Plus"],
        [/\[\]/, "SquareBrackets"]
      ]
    end
  end
end
