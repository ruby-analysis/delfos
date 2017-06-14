# frozen_string_literal: true

require_relative "call_handler"
require "./fixtures/a_usage"

module Delfos
  module MethodTrace
    RSpec.describe CallHandler do
      let(:path) { "fixtures/a_usage.rb" }
      let(:a) { A.new }

      let(:trace_point) do
        double "TracePoint",
          self: a,
          method_id: :some_method,
          path: path,
          lineno: 2
      end

      subject(:handler) do
        described_class.new(trace_point)
      end

      before do
        Delfos.application_directories = application_directories
      end

      let(:application_directories) do
        ["fixtures"]
      end

      describe "#called_method" do
        it do
          expect(subject.called_method.object)      .to eq a
          expect(subject.called_method.method_name) .to eq "some_method"
          expect(subject.called_method.file)        .to eq path
          expect(subject.called_method.line_number) .to eq 2
          expect(subject.called_method.class_method).to eq false
        end
      end

      describe "#call_site" do
        subject(:handler) do
          described_class.new(trace_point)
        end

        it "determines the call site information" do
          expect(handler.call_site.line_number)      .to be_a Integer
          expect("/" + handler.call_site.file)       .to be_a String
          expect(handler.call_site.container_method) .to be_a CodeLocation::Method
          expect(handler.call_site.called_method)    .to be_a CodeLocation::Method
        end
      end

      describe "#perform" do
        let(:call_site_logger) { double "call_site_logger", log: nil }
        let(:call_site) { double "call_site", called_method_path: called_method_path }
        let(:called_method_path) { "fixtures/a.rb" }

        before do
          allow(Delfos).to receive(:call_site_logger).and_return call_site_logger
          allow(CallStack).to receive(:push)
          allow(subject).to receive(:call_site).and_return(call_site)
        end

        context "with irrelevant call sites" do
          let(:paths) { ["/usr/local/"] }
          it "skips" do
            expect(CallStack).not_to receive(:push)
            expect(call_site_logger).not_to receive(:log)
          end
        end

        context "with relevant call sites" do
          let(:called_method_path) { "fixtures/a.rb" }
          let(:application_directories) { ["fixtures"] }

          it "pushes the call site on the stack" do
            expect(CallStack).to receive(:push)
            subject.perform
          end

          it "logs the call site" do
            expect(call_site_logger).
              to receive(:log).
              with(call_site)
            subject.perform
          end
        end
      end
    end
  end
end
