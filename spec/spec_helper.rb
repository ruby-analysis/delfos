# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require "byebug"
require "delfos"
require_relative "support/logging"

require "ostruct"

require_relative "support/code_climate" if ENV["CI"]
require_relative "support/timeout" if ENV["TIMEOUT"]

require_relative "support/call_sites"
require_relative "support/helper_methods"
require_relative "support/neo4j"
require_relative "support/show_class_instance_variables"
require_relative "support/reset"
require_relative "support/temp_directory"
require_relative "support/web_mock"
require_relative "support/stub_neo4j"

RSpec.configure do |c|
  c.disable_monkey_patching!

  c.expect_with :rspec do |m|
    m.syntax = :expect
  end

  c.example_status_persistence_file_path = ".rspec-failed-examples"

  c.mock_with :rspec do |m|
    m.syntax = :expect
  end
end
