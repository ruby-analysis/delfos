class SuperClass
  def a_method
  end
end

class SubClass < SuperClass
  #alias_method :_a_method, :a_method
  #undef :a_method

  def calls_a_method
    a_method
  end
end


SubClass.new.a_method
