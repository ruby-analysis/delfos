class ClassMethodCallsAnInstanceMethod
  def self.a_class_method
    HasInstanceMethod.new.an_instance_method
  end
end

class HasInstanceMethod
  def an_instance_method
  end
end
