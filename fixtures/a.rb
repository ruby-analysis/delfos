# frozen_string_literal: true
class A
  def some_method(*args, **keyword_args)
    B.new.another_method(self, *args, **keyword_args) # cs1 e-step1
    C.new.method_with_no_more_method_calls # cs3 e-step
    D.some_class_method
  end

  def to_s
    "a"
  end
end

class D
  def self.some_class_method

  end
end
