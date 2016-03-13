# frozen_string_literal: true
$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require "byebug"

RSpec.configure do |c|
  c.before(:each) do
    require_relative "../lib/delfos"
    Delfos.reset!
  end

  c.after(:each) do
    require_relative "../lib/delfos"
    Delfos.reset!
  end
end
