# frozen_string_literal: true
module Delfos
  module Patching
    class MethodCallingException < RuntimeError
      def initialize(method:, args:, keyword_args:, block:, initial_cause:)
        message = "Exception occurred whilst executing a Delfos intercepted method"
        message += "\n"
        message += format_args(method: method, args: args, keyword_args: keyword_args, block: block,
                               initial_cause: initial_cause)

        super(message)
      end

      def format_args(args)
        length = args.keys.map(&:to_s).map(&:length).max

        args.map { |k, v| format_arg(k, v, length) }.join("\n")
      end

      def format_arg(k, v, length)
        "#{k.to_s.ljust(length)}: #{v.inspect}"
      end
    end
  end
end
