# frozen_string_literal: true

require_relative "code_location/method"
require_relative "code_location/call_site"
require_relative "code_location/container_method_factory"
require_relative "code_location/eval_in_caller"

module Delfos
  module MethodTrace
    module CodeLocation
      class << self
        include EvalInCaller

        def method_from(attrs)
          Method.new(attrs)
        end

        STACK_OFFSET = 8

        def callsite_from(container_method:, called_method:, stack_offset: STACK_OFFSET)
          CallSite.new(
            container_method: container_method,
            called_method:    called_method,
            file:             eval_in_caller("__FILE__", stack_offset),
            line_number:      eval_in_caller("__LINE__", stack_offset),
          )
        end

        def create_container_method
          ContainerMethodFactory.create
        end
      end
    end
  end
end
