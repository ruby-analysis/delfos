require_relative "method_calling_exception"

module Delfos
  module Patching
    MethodArguments = Struct.new(:args, :keyword_args, :block, :should_wrap_exception) do
      def apply_to(method)
        if keyword_args.empty?
          method.call(*args, &block)
        else
          method.call(*args, **keyword_args, &block)
        end
      rescue StandardError => e
        raise unless should_wrap_exception

        raise MethodCallingException, {
          method: method,
          args: args,
          keyword_args: keyword_args,
          block: block,
          initial_cause: e
        }
      end
    end
  end
end

