# frozen_string_literal: true

class Product
  def initialize(price = nil, name = nil)
    @price = price
    @name = name
  end

  def change_name(name)
    @name = name
  end
end
