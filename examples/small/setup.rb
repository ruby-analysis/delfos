# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../../lib", __FILE__)
require "delfos"
file = __FILE__
require "pathname"

app_dir = Pathname.new(File.expand_path(file)) + "../app"
excluded_file = Pathname.new(File.expand_path(file)) + "../app/app_config.rb"

Delfos.configure do |config|
  config.include = app_dir
  config.exclude = excluded_file
end

Delfos.start!

require_relative "./app/product_usage.rb"

Delfos.finish!
