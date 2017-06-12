class InsideFixturesFolder
  def self.evaluate(ruby=nil, &block)
    if block_given?
      self.instance_eval(&block)
    else
      self.instance_eval ruby, __FILE__, __LINE__
    end
  end
end
