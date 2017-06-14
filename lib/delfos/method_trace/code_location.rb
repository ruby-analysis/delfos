require_relative "code_location/method"
require_relative "code_location/call_site"
require_relative "code_location/container_method_factory"

module Delfos
  module MethodTrace
    module CodeLocation
      def self.new_method(attrs)
        CodeLocation::Method.new(attrs)
      end

      def self.new_callsite(attrs)
        CodeLocation::CallSite.new(attrs)
      end

      def self.new_container_method
        CodeLocation::ContainerMethodFactory.create
      end
    end
  end
end
