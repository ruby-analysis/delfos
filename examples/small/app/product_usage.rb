require_relative "product"

class ProductUsage
  def self.perform
    product = Product.new
    product.change_name("Car")
  end
end

ProductUsage.perform
