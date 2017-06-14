def outer
  inner rescue nil
end

def inner
  wait_for_it___
end

def wait_for_it___
  boom
end

def boom
  raise "boom"
end

def another

end

outer

another
