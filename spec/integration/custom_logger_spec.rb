# frozen_string_literal: true

require "delfos"
require "delfos/neo4j"

RSpec.describe "integration with a custom call_stack_logger" do
  let(:loading_code) do
    lambda do
      load "fixtures/a_usage.rb"
    end
  end

  let(:call_site_logger) { double "call stack logger", log: nil, save_call_stack: nil, finish!: nil }

  before do
    WebMock.disable_net_connect! allow_localhost: false

    Delfos.configure do |c|
      c.include = "fixtures"
      allow(c).to receive(:call_site_logger).and_return call_site_logger
    end
    Delfos.start!
  end

  after do
    WebMock.disable_net_connect! allow_localhost: true
  end

  it "doesn't hit the network" do
    expect(loading_code).not_to raise_error
  end

  it "logs the call sites" do
    cl = Delfos::MethodTrace::CodeLocation
    expect(call_site_logger).to receive(:log) do |call_site, uuid, step_number|
      expect(call_site)                  .to be_a cl::CallSite
      expect(call_site.called_method)    .to be_a cl::Method
      expect(call_site.container_method) .to be_a cl::Method

      expect(uuid)                       .to be_a String
      expect(step_number)                .to be_a Integer
    end.exactly(11).times

    loading_code.()
  end
end
