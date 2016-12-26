module Delfos
  module Patching
    #containers for the individual modules created to log each method call
    module ClassMethodLogging
    end

    module InstanceMethodLogging
    end

    module ModuleDefiningMethods
      def safe_class_name
        module_safe_name(klass.name || klass.to_s)
      end

      def safe_method_name
        module_safe_name(name.to_s)
      end

      def find_or_create(container, module_name)
        module_name = module_name.gsub(":", "_")

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
        m = MethodCachingModule.new

        container.const_set(module_name, m)
        return m
      rescue Exception => e
        m
      end

      def module_definition(&block)
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

      def add_namespace ns, code
        "module #{ns}\n#{code}\nend"
      end

      def nesting(n, code)
        n.split("::").reverse.each do |ns|
          code = add_namespace(ns, code)
        end

        code
      end

      def module_safe_name(string, uppercase_first_letter = true)
        string = string.sub(/^[a-z\d]*/) { $&.capitalize }

        string
          .gsub(/(?:_|(\/))([a-z\d]*)/) { "#{$1}#{$2.capitalize}" }
          .gsub('/', '::')
          .gsub(/\=/, "Equals")
          .gsub(/\<\=\>/, "Spaceship")
          .gsub(/\<\=/, "LessThanOrEqualTo")
          .gsub(/\>\=/, "GreaterThanOrEqualTo")
          .gsub(/\#\<Class\:0x(.*)\>/){"AnonymousClass_#{$1}"}
          .gsub(/\>/, "GreaterThan")
          .gsub(/\</, "LessThan")
          .gsub(/!\~/, "NotMatchOperator")
          .gsub(/\~/, "MatchOperator")
          .gsub(/\?/, "QuestionMark")
          .gsub(/\!$/, "Bang")
          .gsub(/\+/, "Plus")
          .gsub(/\[\]/, "SquareBrackets")
      end
    end

    # This class caches the original method source_locations just before
    # instances of these modules are prepended
    class MethodCachingModule < Module
      def prepend_features(other)
        #method_sources = other.instance_methods(false).map{|m| other.instance_method(m) }.map{|m| ["InstanceMethod_#{m.name}", *m.source_location]}

        #method_sources.each do |key, file, line_number|
        #  MethodCache.append(klass, key, file, line_number)
        #end

        super
      end

      def initialize
        super() do
          yield self if block_given?
        end
      end
    end



  end
end

