module Delfos
  class MethodTrace
    module EvalInCaller
      def eval_in_caller(s, offset, &block)
        other = binding.of_caller(offset)

        other.eval(s)
      end
    end
  end
end
