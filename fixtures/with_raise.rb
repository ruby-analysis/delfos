def boom
  raise "boom"
end

def execution_1
  boom rescue nil
  another_method
end

def another_method
end

execution_1
another_method
