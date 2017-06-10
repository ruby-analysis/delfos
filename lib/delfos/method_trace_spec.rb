require_relative "method_trace"
require "./fixtures/a"

module Delfos
  RSpec.describe MethodTrace do
    let(:return_handler) { double "Return Handler", perform: nil }
    let(:call_handler) { double "Call Handler", perform: nil }
    let(:raise_handler) { double "Raise Handler", perform: nil }

    before do
      Delfos.setup! application_directories: ["fixtures"]
      # we manually start the TracePoints in our tests so
      # disable the automatically started ones
      described_class.disable!
    end

    after do
      described_class.disable!
    end

    describe "on_call" do
      before do
        expect(MethodTrace::CallHandler).
          to receive(:new).
          and_return(call_handler).
          at_least(:once)
      end
      it do
        expect(call_handler).to receive(:perform).at_least(:once)

        described_class.on_call.enable
        A.new.some_method
      end
    end

    describe "on_return" do
      before do
        expect(MethodTrace::ReturnHandler).
          to receive(:new).
          and_return(return_handler).
          at_least(:once)
      end

      it do
        expect(return_handler).to receive(:perform).at_least(:once)

        described_class.on_return.enable
        A.new.some_method
      end
    end

    describe "on_raise" do
      before do
        expect(MethodTrace::RaiseHandler).
          to receive(:new).
          and_return(raise_handler).
          at_least(:once)
      end

      it do
        expect(raise_handler).to receive(:perform).at_least(:once)

        described_class.on_raise.enable
        expect{A.boom!}.to raise_error RuntimeError
      end
    end
  end
end
