# frozen_string_literal: true
require_relative "method_override"

class BasicObject
  def self.method_added(name)
    ::Delfos::Patching::MethodOverride.setup(self, name, class_method: false)
  end

  def self.singleton_method_added(name)
    return if %i(define_method extended included inherited method_added singleton_method_added).include?(name)

    ::Delfos::Patching::MethodOverride.setup(self, name, class_method: true)
  end
end
