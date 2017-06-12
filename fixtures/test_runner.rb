require_relative "a"
require_relative "b"

class TestRunner
  def self.run_custom_logger_spec
    a = A.new.some_method
    B.new.another_method a
  end
end
