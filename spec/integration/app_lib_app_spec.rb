# frozen_string_literal: true

require "delfos"

describe "integration with a customer call_stack_logger" do
  let(:loading_code) do
    lambda do
      load "fixtures/app/include_this/start_here.rb"
    end
  end

  let(:call_site_logger) { double "call stack logger", log: nil, save_call_stack: nil }
  before do
    WebMock.disable_net_connect! allow_localhost: false

    Delfos.setup!(
      application_directories: ["fixtures/app/include_this"],
      call_site_logger: call_site_logger,
    )
  end

  after do
    WebMock.disable_net_connect! allow_localhost: true
  end

  context "with app code calling lib code which calls back into lib code" do
    it "logs the call sites" do
      expect(call_site_logger).to receive(:log) do |call_site|
        expect(call_site)                  .to be_a Delfos::CodeLocation::CallSite
        expect(call_site.called_method)    .to be_a Delfos::CodeLocation::Method
        expect(call_site.container_method) .to be_a Delfos::CodeLocation::Method
      end.exactly(3).times

      loading_code.()
    end

    pending "Issue #14 - saves the call stack" do
      # this is not necessarily the correct failing test yet
      expect(call_site_logger).to receive(:save_call_stack) do |call_sites, execution_count|
        expect(call_sites)        .to be_an Array
        expect(call_sites.length) .to eq 11
        expect(execution_count)   .to eq 1
      end

      loading_code.()
    end
  end
end
