# frozen_string_literal: true
$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require "byebug"
require "delfos"

require "ostruct"

require_relative "support/timeout" if ENV["TIMEOUT"]

require_relative "support/logging"
require_relative "support/neo4j"
require_relative "support/web_mock"
require_relative "support/helper_methods"
require_relative "support/show_class_instance_variables"
require_relative "support/code_climate" if ENV["CI"]

RSpec.configure do |c|
  c.expect_with :rspec do |c|
    c.syntax = :expect
  end

  c.example_status_persistence_file_path = ".rspec-failed-examples"

  c.mock_with :rspec do |c|
    c.syntax = :expect
  end

  def reset_all
      Delfos.reset! if Delfos.respond_to?(:reset!)
  rescue NameError => e
    raise unless e.message["Delfos::Patching"]
  end

  c.before(:suite) do
    reset_all
  end

  c.after(:each) do
    Delfos::Setup.reset_batch!
  end

  c.before(:each) do
    reset_all

    ShowClassInstanceVariables.variables_for(Delfos)
    Delfos.logger = $delfos_test_logger if defined? $delfos_test_logger
  end
end
