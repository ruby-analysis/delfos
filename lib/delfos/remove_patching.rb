# frozen_string_literal: true
class BasicObject
  def self.method_added(*_args)
    nil
  end

  def self.singleton_method_added(*_args)
    nil
  end
  
  def self.inherited(*_args)
    nil
  end
end
