class This
  def self.send_message; end
end

class That < This
end

class SomeOther < This
end

class SoMuchCoupling
  def self.found_in_here; end
end

class HereIsSomeMore
  def self.for_good_measure; end
end
