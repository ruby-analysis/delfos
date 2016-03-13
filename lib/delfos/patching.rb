# frozen_string_literal: true
module Delfos
  class Patching
    def initialize(klass, name, private_methods, class_method)
      @klass, @name, @private_methods, @class_method =
        klass, name, private_methods, class_method
    end
    attr_reader :klass, :name, :private_methods, :class_method



    def self.setup_method_call_logging(klass, name, private_methods, class_method:)
      new(klass, name, private_methods, class_method).setup
    end

    def setup
      return if bail?
      record_method_adding(klass, original_method, class_method: class_method)
      class_method = class_method()
      original_method = original_method()

      method_defining_method.call(name) do |*args, **keyword_args, &block|
        ::Delfos::MethodLogging.log(
          self,
          args, keyword_args, block,
          class_method, caller.dup, binding.dup,
          original_method
        )

        method_to_call = class_method ? original_method : original_method.bind(self)

        if keyword_args.empty?
          method_to_call.call(*args, &block)
        else
          method_to_call.call(*args, **keyword_args, &block)
        end
      end
    end

    private

    def bail?
      already_added? || is_private_method?  || exclude?
    end

    def is_private_method?
      private_methods.include?(name.to_sym)
    end

    def exclude?
       ::Delfos::MethodLogging.exclude_from_logging?(original_method)
    end

    def already_added?
      method_has_been_added?(klass, name, class_method: class_method) 
    end

    def original_method
      class_method ? klass.singleton_method(name) : klass.instance_method(name)
    end

    def method_defining_method
      class_method ? klass.method(:define_singleton_method) : klass.method(:define_method)
    end

    def method_has_been_added?(klass, name, class_method:)
      return false unless self.class.added_methods[self]
      return false unless self.class.added_methods[self][klass]

      type = class_method ? "class_method" : "instance_method"
      self.class.added_methods[klass]["#{type}_#{name}"]
    end

    def self.added_methods
      @added_methods ||= {}
    end

    def record_method_adding(klass, meth, class_method:)
      return true if method_has_been_added?(klass, meth, class_method: class_method)

      type = class_method ? "class_method" : "instance_method"
      self.class.added_methods[klass] ||= {}
      self.class.added_methods[klass]["#{type}_#{meth.name}"] = meth.source_location
    end
  end
end


