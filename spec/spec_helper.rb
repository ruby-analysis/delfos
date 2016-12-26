# frozen_string_literal: true
$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require "byebug"
require "delfos"

require "ostruct"

unless ENV["CI"]
  # only log errors in dev
  $delfos_test_logger = Object.new.tap do |o|
    def o.debug(_s)
      nil
    end

    def o.info(_s)
      nil
    end

    def o.log(_s)
      nil
    end

    def o.error(s)
      puts s
    end
  end
end

require_relative "support/timeout" if ENV["TIMEOUT"]

require_relative "support/neo4j"
require_relative "support/web_mock"
require_relative "support/helper_methods"
require_relative "support/show_class_instance_variables"

RSpec.configure do |c|
  c.expect_with :rspec do |c|
    c.syntax = :expect
  end

  c.example_status_persistence_file_path = ".rspec-failed-examples"

  c.mock_with :rspec do |c|
    c.syntax = :expect
  end

  c.before(:suite) do
    Delfos.reset!
  end

  c.before(:each) do
    Delfos.reset!
    ShowClassInstanceVariables.variables_for(Delfos)
    Delfos.logger = $delfos_test_logger
  end
end
