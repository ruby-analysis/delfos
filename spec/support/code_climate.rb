# frozen_string_literal: true

require "simplecov"

SimpleCov.start do
  add_filter "/vendor/"
  add_filter "/examples/"
  add_filter "/fixtures/"
  add_filter "/pkg/"
  add_filter "/spec/"
end
