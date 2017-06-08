$:.unshift File.expand_path("../../../lib", __FILE__)
require "delfos"
file = __FILE__
require "pathname"
app_dir = Pathname.new(File.expand_path(file)) + "../app"
Delfos.setup! application_directories: app_dir

require_relative "./app/product_usage.rb"
