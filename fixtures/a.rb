class A
  def some_method(*args, **keyword_args)
    B.new.another_method(self, *args, **keyword_args)
  end
end
