unless ENV["CI"]
  # only log errors in dev
  $delfos_test_logger = Object.new.tap do |o|
    def o.debug(_s)
      nil
    end

    def o.info(_s)
      nil
    end

    def o.log(_s)
      nil
    end

    def o.error(s)
      puts s
    end
  end
end


