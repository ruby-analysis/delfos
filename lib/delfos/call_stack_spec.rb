# frozen_string_literal: true

require_relative "call_stack"

module Delfos
  RSpec.describe CallStack do
    let(:call_site_logger) { double "call_site_logger", log: nil }
    let(:call_site) { double "call site", container_method: container_method, called_method: called_method }
    let(:called_method) { double "called_method" }
    let(:container_method) { double "called_method" }

    before do
      allow(Delfos).to receive(:call_site_logger).and_return call_site_logger

      other = Thread.new do
        @other_stack = described_class.stack
        @other_memoised_stack = described_class.stack
      end

      other.join

      expect(@other_stack)          .to be_a described_class::Stack
      expect(@other_memoised_stack) .to be_a described_class::Stack
      expect(@other_stack)          .to be @other_memoised_stack
    end

    describe ".stack" do
      it "returns a thread local stack" do
        first_call = described_class.stack
        second_call = described_class.stack

        expect(first_call).to be second_call

        expect(@other_stack).not_to eq first_call
      end
    end

    describe ".push" do
      it "logs the call site" do
        expect(call_site_logger).
          to receive(:log).
          with(call_site, an_instance_of(String), an_instance_of(Integer))

        CallStack.push call_site
      end
    end
  end
end
