class This
  def self.send_message; end
end

That = Class.new This
SomeOther = Class.new This

class SoMuchCoupling
  def self.found_in_here; end
end

class HereIsSomeMore
  def self.for_good_measure; end
end
