class ExcludeThis
  def another_method
    nested
  end

  def nested
    further
  end

  def further
    IncludeThis::CalledAppClass.new.next_method
  end
end
