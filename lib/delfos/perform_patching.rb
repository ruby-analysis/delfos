# frozen_string_literal: true
module Delfos
  class Patching
    def self.setup_method_call_logging(klass, name, private_methods, class_method:)
      return if method_has_been_added?(klass, name, class_method: class_method)
      return if private_methods.include? name.to_sym
      original_method = class_method ? klass.singleton_method(name) : klass.instance_method(name)
      return if ::Delfos::MethodLogging.exclude_from_logging?(original_method)
      record_method_adding(klass, original_method, class_method: class_method)

      method_defining_method = class_method ? klass.method(:define_singleton_method) : klass.method(:define_method)

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

    def self.method_has_been_added?(_klass, name, class_method:)
      return false unless added_methods[self]

      type = class_method ? "class_method" : "instance_method"
      added_methods[self]["#{type}_#{name}"]
    end

    def self.added_methods
      @added_methods ||= {}
    end

    def self.record_method_adding(klass, meth, class_method:)
      return true if method_has_been_added?(klass, meth, class_method: class_method)

      type = class_method ? "class_method" : "instance_method"
      added_methods[klass] ||= {}
      added_methods[klass]["#{type}_#{meth.name}"] = meth.source_location
    end
  end
end

class BasicObject
  def self.method_added(name)
    return if name == __method__

    ::Delfos::Patching.setup_method_call_logging(self, name, private_instance_methods, class_method: false)
  end

  def self.singleton_method_added(name)
    return if name == __method__

    ::Delfos::Patching.setup_method_call_logging(self, name, private_methods, class_method: true)
  end
end
