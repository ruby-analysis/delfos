# frozen_string_literal: true
module ProductAttributes
  def self.included(klass)
    klass.class_eval do
      attr_reader :price
    end
  end
end

class Product
  include ProductAttributes

  def initialize(price = nil, name = nil)
    @price = price
    @name = name
  end

  def change_name(name)
    @name = name
  end
end
