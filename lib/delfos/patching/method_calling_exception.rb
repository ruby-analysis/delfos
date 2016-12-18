module Delfos
  module Patching
    class ::Delfos::MethodCallingException < Exception
      def initialize(method:, args:, keyword_args:,block:,class_method:, cause: e)
        message = "Exception occurred whilst executing a Delfos intercepted method"
        message = message + "\n"
        message = message + format_args({method: method, args: args, keyword_args: keyword_args, block: block, 
                                         class_method: class_method, cause: cause})

        super(message)
      end

      def format_args(args)
        length = args.keys.map(&:to_s).map(&:length).max

        args.map{  |k,v| format_arg(k,v,length) }.join("\n")
      end

      def format_arg(k,v,length)
        "#{k.to_s.ljust(length)}: #{v.inspect}"
      end
    end
  end
end


