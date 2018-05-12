# frozen_string_literal: true

require "binding_of_caller"

module Delfos
  module MethodTrace
    module CodeLocation
      module EvalInCaller
        def eval_in_caller(to_eval, offset)
          binding.of_caller(offset).eval(to_eval)
        end
      end
    end
  end
end
