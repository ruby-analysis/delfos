unless ENV["CI"]
  # only log errors in dev
  $delfos_test_logger = Object.new

  $delfos_test_logger.instance_eval do
    class << self
      attr_accessor :level

      def debug(_s)
        nil
      end

      def info(_s)
        nil
      end

      def log(_s)
        nil
      end

      def error(s)
        if level >= Logger::ERROR
          puts s
        end
      end
    end
  end
end


