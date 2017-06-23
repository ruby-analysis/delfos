# frozen_string_literal: true

require_relative "code_location/method"
require_relative "code_location/call_site"
require_relative "code_location/container_method_factory"

module Delfos
  module MethodTrace
    module CodeLocation
      class << self
        def method_from(attrs)
          Method.new(attrs)
        end

        def callsite_from(attrs)
          CallSite.new(attrs)
        end

        def create_container_method
          ContainerMethodFactory.create
        end
      end
    end
  end
end
