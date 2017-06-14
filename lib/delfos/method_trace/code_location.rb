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

        def new_method(attrs)
          Method.new(attrs)
        end

        STACK_OFFSET = 7

        def new_callsite(attrs)
          CallSite.new(
            attrs.merge(
              file:        eval_in_caller("__FILE__", STACK_OFFSET),
              line_number: eval_in_caller("__LINE__", STACK_OFFSET),
            ),
          )
        end

        def new_container_method
          ContainerMethodFactory.create
        end
      end
    end
  end
end
