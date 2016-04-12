# frozen_string_literal: true
class A
  def some_method(*args, **keyword_args)
    B.new.another_method(self, *args, **keyword_args)
    B.new.another_method(self, B, b: B.new)
  end
end
