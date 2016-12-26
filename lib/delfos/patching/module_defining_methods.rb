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
        safe_method_name = safe_method_name()
        safe_class_name = safe_class_name()
        module_type = class_method ? "ClassMethodLogging" : "InstanceMethodLogging"
        find_or_create = method(:find_or_create)

        m = nil
        Patching.const_get(module_type).instance_eval do
          namespace = find_or_create.call(self, safe_class_name)

          m = find_or_create.call(namespace, safe_method_name)

          m.class_eval(&block) if block_given?

          m
        end
      end

      private

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

      def create(container, module_name)
        m = Module.new

        container.const_set(module_name, m)
        return m
      rescue Exception => e
        m
      end

      def module_safe_name(string, _uppercase_first_letter = true)
        string = string.sub(/^[a-z\d]*/) { $&.capitalize }

        string.
          gsub(/(?:_|(\/))([a-z\d]*)/) { "#{Regexp.last_match(1)}#{Regexp.last_match(2).capitalize}" }.
          gsub("/", "::").
          gsub(/\=/, "Equals").
          gsub(/\<\=\>/, "Spaceship").
          gsub(/\<\=/, "LessThanOrEqualTo").
          gsub(/\>\=/, "GreaterThanOrEqualTo").
          gsub(/\#\<Class\:0x(.*)\>/) { "AnonymousClass_#{Regexp.last_match(1)}" }.
          gsub(/\>/, "GreaterThan").
          gsub(/\</, "LessThan").
          gsub(/!\~/, "NotMatchOperator").
          gsub(/\~/, "MatchOperator").
          gsub(/\?/, "QuestionMark").
          gsub(/\!$/, "Bang").
          gsub(/\+/, "Plus").
          gsub(/\[\]/, "SquareBrackets")
      end
    end
  end
end
