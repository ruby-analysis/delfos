# frozen_string_literal: true

require_relative "offline_call_site_logger"
require "tempfile"

module Delfos
  module Neo4j
    RSpec.describe OfflineCallSiteLogger do
      let(:call_site_query) do
        double "call_site_query", query: query_body, params: params
      end

      let(:call_site) { double "call site" }
      let(:stack_uuid) { "some uuid" }
      let(:step_number) { 1 }
      let(:query_body) { "query body" }
      let(:params) { {some: "params"} }
      let(:single_output_line) { "#{query_body}\t#{params.to_json}\tnot_imported\n" }
      let(:tempfile) { Tempfile.new }

      before do
        expect(CallSiteQuery).
          to receive(:new).with(call_site, stack_uuid, step_number).
          and_return(call_site_query).at_least(:once)

        Delfos.offline_query_filename = tempfile.path
      end

      describe "#log" do
        it "doesn't flush yet to the file" do
          subject.log(call_site, stack_uuid, step_number)
          expect(File.readlines(Delfos.offline_query_filename)).to eq []
        end

        it "flushes the file every 100 queries" do
          100.times do
            subject.log(call_site, stack_uuid, step_number)
          end
          lines = File.readlines(Delfos.offline_query_filename)
          expect(lines.length).to eq 100
          expect(lines.first).to eq single_output_line
        end
      end

      describe "#finish!" do
        it "flushes and closes the file" do
          subject.log(call_site, stack_uuid, step_number)
          expect(File.readlines(Delfos.offline_query_filename)).to eq []
          subject.finish!
          expect(File.readlines(Delfos.offline_query_filename)).to eq [single_output_line]
        end
      end
    end
  end
end
