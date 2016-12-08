# frozen_string_literal: true
class A
  def some_method(*args, **keyword_args)
    B.new.another_method(self, *args, **keyword_args)
    C.new.method_with_no_more_method_calls
  end
end
