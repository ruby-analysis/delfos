class SomeRandomClass
  $class_method_line_number = __LINE__ + 1
  def self.some_class_method
  end

  def some_externally_called_public_method
    $call_site_line_number = __LINE__ + 1
    some_public_method
  end

  $instance_method_line_number = __LINE__ + 1
  def some_public_method
    some_private_method
  end

  private

  def some_private_method
    "private"
  end
end


