# frozen_string_literal: true
class B
  def another_method(that, *_args, **_keyword_args)
    that.to_s

    C.new.method_with_no_more_method_calls

    C.new.third(self)
  end

  def cyclic_dependency(s)
    s.fourth
  end
end

class C
  def third(other)
    other.cyclic_dependency(self)
  end

  def fourth
    fifth
  end

  def fifth
    sixth
  end

  def sixth
    #execution chain ends here
  end

  def method_with_no_more_method_calls
  end
end
