# frozen_string_literal: true

require "binding_of_caller"

module Delfos
  module MethodTrace
    module CodeLocation
      module EvalInCaller
        def eval_in_caller(s, offset, &block)
          other = binding.of_caller(offset)

          other.eval(s)
        end
      end
    end
  end
end
