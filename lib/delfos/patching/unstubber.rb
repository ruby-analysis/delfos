# frozen_string_literal: true
module Delfos
  module Patching
    class Unstubber
      extend ModuleDefiningMethods

      def self.unstub_all!
        MUTEX.synchronize do
          Thread.current[:__delfos_disable_patching] = true
        end

        MethodCache.added_methods.each do |klass, methods|
          next if methods.empty?

          klass = eval(klass)

          class_methods, instance_methods = methods.partition{|key, _|key[/^ClassMethod_/]}

          unstub_methods(klass, class_methods, true)
          unstub_methods(klass, instance_methods, false)
        end

        MUTEX.synchronize do
          Thread.current[:__delfos_disable_patching] = false
        end
      end

      def self.unstub_methods(klass, methods, class_method)
        methods.each do |method_name, _|
          unstub!(klass, method_name, class_method)
        end
      end

      def self.unstub!(klass, method_name, class_method)
        module_definition(klass, method_name, class_method) do |m|
          begin
            remove_method :"#{method_name}"
          rescue NameError => e
            raise unless e.message["method `#{method_name}' not defined in"]
          end
        end
      end
    end
  end
end
