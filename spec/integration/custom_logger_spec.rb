# frozen_string_literal: true

require "delfos"
require "delfos/neo4j"

RSpec.describe "integration with a custom call_stack_logger" do
  include DelfosSpecs.stub_neo4j

  let(:loading_code) do
    lambda do
      load "fixtures/a_usage.rb"
    end
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
