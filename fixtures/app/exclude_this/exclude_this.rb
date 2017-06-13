class ExcludeThis
  def another_method
    IncludeThis::CalledAppClass.new.next_method
  end
end
