class InstanceMethodCallsAClassMethod
  def an_instance_method
    HasClassMethod.a_class_method
  end
end

class HasClassMethod
  def self.a_class_method
    1
  end
end
