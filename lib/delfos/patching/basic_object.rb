# frozen_string_literal: true
require_relative "method_override"

class BasicObject
  def self.method_added(name)
    return if %i(to_s singleton_method_added method_added).include?(name)

    ::Delfos::Patching::MethodOverride.setup(self, name, private_instance_methods, class_method: false)
  end

  def self.singleton_method_added(name)
    # can't currently support to_s and name as those are used inside the method logging code
    return if %i(to_s name extended included inherited method_added singleton_method_added).include?(name)
    return if ::Delfos::MethodLogging.exclude?(method(name))

    ::Delfos::Patching::MethodOverride.setup(self, name, private_methods, class_method: true)
  end
end
