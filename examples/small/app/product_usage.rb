# frozen_string_literal: true

require_relative "product"
require_relative "app_config"

class ProductUsage
  def self.perform
    AppConfig.configure
    product = Product.new
    product.change_name("Car")
  end
end

ProductUsage.perform
