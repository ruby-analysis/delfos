# frozen_string_literal: true
require_relative "patching"

module Delfos
  class Patching
    module BasicObject
      def method_added(name)
        return if %i(to_s method_added).include?(name)

        ::Delfos::Patching.perform(self, name, private_instance_methods, class_method: false)
      end

      def singleton_method_added(name)
        # can't currently support to_s and name as those are used inside the method logging code
        return if %i(to_s name inherited method_added singleton_method_added).include?(name)
        return if ::Delfos::MethodLogging.exclude_from_logging?(method(name))

        ::Delfos::Patching.perform(self, name, private_methods, class_method: true)
      end
    end
  end
end
