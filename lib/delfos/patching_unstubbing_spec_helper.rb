# This existence of these `Unstubbing` modules are an unfortunate side effect of trying to
# test something that redefines methods.  In order to not call the logging
# defined in `Delfos::Patching#setup` multiple times we have to keep track of
# and remove the method definitions and replace with the original definition
# (or as close to the original as possible).
#
# If there is a better way to test Delfos::Patching without doing this then
# please suggest or replace with a cleaner alternative
module Unstubbing
  module ClassMethods
    def add_instance_to_unstub!(object)
      instances_to_unstub.push(object)
    end

    def unstub_all!
      instances_to_unstub.each(&:unstub!)
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
      original = original_method
      class_method = class_method()
      performer = method(:perform_call)

      method_defining_method.call(name) do |*args, **keyword_args, &block|
        method_to_call = class_method ? original : original.bind(self)
        performer.call(method_to_call, args, keyword_args, block)
      end
    end
  end
end
