# frozen_string_literal: true

require_relative "method_trace"
require "./fixtures/a"

module Delfos
  module MethodTrace
    RSpec.describe Setup do
      let(:return_handler) { double "Return Handler", perform: nil }
      let(:call_handler) { double "Call Handler", perform: nil }
      let(:raise_handler) { double "Raise Handler", perform: nil }

      before do
        Delfos.configure do |c|
          c.include = "fixtures"
        end

        allow(CallStack).to receive(:pop)

        allow(MethodTrace::CallHandler).
          to receive(:new).
          and_return(call_handler)
      end

      after(:each) do
        puts "after in spec"
        Delfos.reset_config!
      end

      describe "#on_call" do
        before do
          expect(MethodTrace::CallHandler).
            to receive(:new).
            and_return(call_handler).
            at_least(:once)
        end

        it do
          expect(call_handler).to receive(:perform).at_least(:once)

          subject.on_call.enable
          A.new.some_method
        end
      end

      describe "#on_return" do
        it do
          expect(CallStack).to receive(:pop).at_least(:once)

          subject.on_return.enable
          A.new.some_method
        end
      end
    end
  end
end
