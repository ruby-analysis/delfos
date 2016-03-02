require_relative "b"

class A
  def some_method
    B.new.another_method(self)
  end
end
