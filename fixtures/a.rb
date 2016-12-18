# frozen_string_literal: true
class A
  def some_method(*args, **keyword_args)
    B.new.another_method(self, *args, **keyword_args) # cs1 e-step1
    C.new.method_with_no_more_method_calls # cs3 e-step
  end

  def to_s
    "a"
  end
end
