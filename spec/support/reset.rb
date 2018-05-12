# frozen_string_literal: true

module DelfosSpecs
  def self.reset!
    Delfos::MethodTrace.disable!

    Delfos.config&.call_site_logger&.reset!
    reset_config!
  end

  def self.reset_config!
    Delfos.instance_eval { @config = nil }
  end
end

RSpec.configure do |c|
  c.before(:each) do
    DelfosSpecs.reset!
    Delfos.configure { |config| config.logger = DelfosSpecs.logger }
  end

  c.after(:each) do
    allow(Delfos).to receive(:config).and_call_original if Delfos.config.is_a?(RSpec::Mocks::TestDouble)

    if Delfos.config&.call_site_logger.is_a? RSpec::Mocks::TestDouble
      allow(Delfos.config).to receive(:call_site_logger).and_call_original
    end

    DelfosSpecs.reset!
  end
end
