# frozen_string_literal: true

require "binding_of_caller"

module Delfos
  module MethodTrace
    module CodeLocation
      module EvalInCaller
        def eval_in_caller(s, offset)
          binding.of_caller(offset).eval(s)
        end
      end
    end
  end
end
