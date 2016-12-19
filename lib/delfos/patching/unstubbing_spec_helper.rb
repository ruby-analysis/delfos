# frozen_string_literal: true

# These `Unstubbing` modules because we are testing something that redefines
# methods.

# We don't want to call the logging defined in
# `Delfos::Patching::MethodOverride#setup` multiple times. So we replace with
# the original definition, or to as close as possible.

# If there is a better way to do this please suggest

module Delfos
  module Patching
    module Unstubbing
      module ClassMethods
        def add_instance_to_unstub!(object)
          instances_to_unstub.push(object)
        end

        def unstub_all!
          instances_to_unstub.each(&:unstub!)
          @instances_to_unstub = []
        end

        private

        def instances_to_unstub
          @instances_to_unstub ||= []
        end
      end

      module InstanceMethods
        def initialize(*args)
          super(*args)
          self.class.add_instance_to_unstub!(self) unless bail?
        end

        # This method is the inverse of `Delfos::Patching::MethodOverride#setup`
        def unstub!
          method = MethodCache.find(klass, key)
          return unless method

          if class_method
            ::Delfos::Patching::MethodOverride.unsetup(klass, name, klass.private_methods, class_method: true)
          else
            ::Delfos::Patching::MethodOverride.unsetup(klass, name, klass.private_instance_methods, class_method: false)
          end
        end
      end
    end
  end
end
