# frozen_string_literal: true
module Delfos
  module Patching
    class Unstubber
      extend ModuleDefiningMethods

      def self.unstub_all!
        MUTEX.synchronize do
          Thread.current[:__delfos_disable_patching] = true
        end

        MethodCache.each_method do |klass_name, method, class_method|
          klass = eval(klass_name)

          unstub!(klass, method.name, class_method)
        end

        MUTEX.synchronize do
          Thread.current[:__delfos_disable_patching] = false
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
