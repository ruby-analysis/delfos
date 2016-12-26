module Delfos
  module Patching
    class Unstubber
      include ModuleDefiningMethods
      attr_reader :klass, :name, :class_method

      def self.unstub_all!
        # TODO change the way we cache methods so we don't have to unpick them
        # like this. Also remove unstubbing from this class
        # We can also remove the `module_definition` from this class so it can
        # be easily reused for stubbing/unstubbing

        MUTEX.synchronize do
          Thread.current[:__delfos_disable_patching] = true
        end

        MethodCache.added_methods.each do |klass, v|
          next if v.empty?

          klass = begin
                    eval klass
                  rescue NameError => e
                    raise unless e.message["AnonymousClass"]
                  end

          class_methods, instance_methods = v.partition{|key, _|key[/^ClassMethod_/]}

          instance_methods.each do |key, method_source|
            name = key.split("InstanceMethod_").last
            class_method = false
            instance = new(klass, name, class_method)

            instance.unstub!
          end
        end

        MUTEX.synchronize do
          Thread.current[:__delfos_disable_patching] = false
        end

      end

      def initialize(klass, name, class_method)
        @klass           = klass
        @name            = name
        @class_method    = class_method
      end

      def unstub!
        method_name = name()

        module_definition do |m|
          m.class_eval do
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
end
