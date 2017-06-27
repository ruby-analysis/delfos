# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require "byebug"
require "delfos"
require_relative "support/logging"

require "ostruct"

require_relative "support/timeout" if ENV["TIMEOUT"]

require_relative "support/call_sites"
require_relative "support/neo4j"
require_relative "support/web_mock"
require_relative "support/helper_methods"
require_relative "support/show_class_instance_variables"
require_relative "support/code_climate" if ENV["CI"]

RSpec.configure do |c|
  c.disable_monkey_patching!

  c.expect_with :rspec do |m|
    m.syntax = :expect
  end

  c.example_status_persistence_file_path = ".rspec-failed-examples"

  c.mock_with :rspec do |m|
    m.syntax = :expect
  end

  c.before(:suite) do |_e|
    FileUtils.rm_rf("./tmp")
  end

  c.before(:each) do |_e|
    ShowClassInstanceVariables.variables_for(Delfos)
    Delfos.configure { |config| config.logger = DelfosSpecs.logger }
  end

  c.after(:each) do |e|
    if Delfos.config.is_a?(RSpec::Mocks::TestDouble)
      allow(Delfos).to receive(:config).and_call_original
    end

    if Delfos.config&.call_site_logger.is_a? RSpec::Mocks::TestDouble
      allow(Delfos.config).to receive(:call_site_logger).and_call_original
    end

    Delfos.reset!
    ShowClassInstanceVariables.last_executed_rspec_test = e.location
  end
end
# rubocop:enable Metrics/BlockLength
