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
          method = Delfos::MethodLogging::AddedMethods.find(klass, key)
          return unless method
          file = File.expand_path(__FILE__)

          cm = class_method
          if cm
            method.unbind.bind(klass)
          else
            klass.send(:define_method, name) do |*args, **kw_args, &block|
              arguments = Delfos::Patching::MethodOverride::MethodArguments.new(args, kw_args, block, cm)
              arguments.apply_to(method.bind(self))
            end
          end
        end
      end
    end
  end
end
