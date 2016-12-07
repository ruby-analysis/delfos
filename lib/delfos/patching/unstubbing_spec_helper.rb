# frozen_string_literal: true
# This existence of these `Unstubbing` modules are an unfortunate side effect of trying to
# test something that redefines methods.  In order to not call the logging
# defined in `Delfos::Patching::MethodOverride#setup` multiple times we have to keep track of
# and remove the method definitions and replace with the original definition
# (or as close to the original as possible).
#
# If there is a better way to test Delfos::Patching without doing this then
# please suggest or replace with a cleaner alternative
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

        # This method is the inverse of `Delfos::Patching#setup`
        def unstub!
          method_selector = method :method_selector

          method_defining_method.call(name) do |*args, **keyword_args, &block|
            arguments = Delfos::Patching::MethodOverride::MethodArguments.new(args, keyword_args, block)
            arguments.perform_call_on(method_selector.call(self))
          end
        end
      end
    end
  end
end
