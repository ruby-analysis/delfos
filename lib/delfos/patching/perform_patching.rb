# frozen_string_literal: true
require_relative "patching"

class BasicObject
  def self.inherited(sub_klass)
    return if self == ::BasicObject or self == ::Object

    ::Delfos::Patching.notify_inheritance(self, sub_klass)
  end

  def self.method_added(name)
    return if %i(to_s).include?(name)
    return if name == __method__

    ::Delfos::Patching.perform(self, name, private_instance_methods, class_method: false)
  end

  def self.singleton_method_added(name)
    # can't support to_s and name yet as those are used inside the method logging code
    # so we need to temporarily disable logging in a Thread safe way
    return if %i(to_s name inherited method_added singleton_method_added).include?(name)
    return if ::Delfos::MethodLogging.exclude_from_logging?(method(name))

    iv_name = "@__delfos_inherited_defined_#{self.name.gsub(/:/, "_")}"

    if name == :inherited && instance_variable_get(iv_name).nil?
      instance_variable_set(iv_name, true)
      original = method(name)

      define_singleton_method name do |*args, &block|
        parent = ancestors.select{|a| a.class == ::Class}[1]
        ::Delfos::Patching.notify_inheritance(parent, self)

        original.call(*args, &block)
      end
    else
      ::Delfos::Patching.perform(self, name, private_methods, class_method: true)
    end
  end
end
