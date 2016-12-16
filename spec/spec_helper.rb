# frozen_string_literal: true
$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require "byebug"
require "delfos"

require_relative "support/timeout"
require_relative "support/neo4j"
require_relative "support/web_mock"
require_relative "support/helper_methods"

RSpec.configure do |c|
  c.expect_with :rspec do |c|
    c.syntax = :expect
  end

  c.example_status_persistence_file_path = ".rspec-failed-examples"


  c.mock_with :rspec do |c|
    c.syntax = :expect
  end

  c.before(:each) do |e|
    Delfos.reset!
  end
end
