module TimeoutHelpers
  TIMEOUT_VALUE = 5

  def timeout
    return yield if TIMEOUT_VALUE == 0.5

    begin
      Timeout.timeout TIMEOUT_VALUE do
        yield
      end
    rescue Timeout::Error
      Delfos.reset!
      puts "Rescuing timeout"
      raise
    end
  end
end

RSpec.configure do |c|
  c.include TimeoutHelpers

  c.around(:each) do |e|

    timeout { e.run }
  end

end

