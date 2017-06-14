# frozen_string_literal: true

require "delfos"
require "delfos/neo4j"

describe "integration with a custom call_stack_logger" do
  let(:loading_code) do
    lambda do
      load "fixtures/a_usage.rb"
    end
  end

  let(:call_site_logger) { double "call stack logger", log: nil, save_call_stack: nil }

  before do
    WebMock.disable_net_connect! allow_localhost: false

    Delfos.setup!(
      application_directories: ["fixtures"],
      call_site_logger: call_site_logger,
    )
  end

  after do
    WebMock.disable_net_connect! allow_localhost: true
  end

  it "doesn't hit the network" do
    expect(loading_code).not_to raise_error
  end

  it "logs the call sites" do
    cl = Delfos::MethodTrace::CodeLocation
    expect(call_site_logger).to receive(:log) do |call_site|
      expect(call_site)                  .to be_a cl::CallSite
      expect(call_site.called_method)    .to be_a cl::Method
      expect(call_site.container_method) .to be_a cl::Method
    end.exactly(11).times

    loading_code.()
  end

  it "saves the call stack" do
    expect(call_site_logger).to receive(:save_call_stack) do |call_sites, execution_count|
      expect(call_sites)        .to be_an Array
      expect(call_sites.length) .to eq 11
      expect(execution_count)   .to eq 1
    end

    loading_code.()
  end
end
