require "simplecov"

SimpleCov.start do
  add_filter "/vendor/"
  add_filter "/examples/"
  add_filter "/fixtures/"
  add_filter "/pkg/"
  add_filter "/spec/"
  add_filter "/lib/delfos/file_system/pathname_extensions.rb" # Copied from standard library
end

