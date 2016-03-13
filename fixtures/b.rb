# frozen_string_literal: true
class B
  def another_method(that, *_args, **_keyword_args)
    that.to_s
  end
end
