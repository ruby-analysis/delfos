# frozen_string_literal: true

require "spec_helper"

require "delfos/neo4j"

require_relative "retryable"

module Delfos
  module Neo4j
    module QueryExecution
      module Batch
        RSpec.describe Retryable do
          before do
            described_class.reset!
            Delfos.configure
          end

          let(:size) { 10 }
          let(:execution) { described_class.new(size: size) }
          let(:transaction_url) { Delfos.config.neo4j.uri_for("/db/data/transaction/1") }
          let(:commit_url) { Delfos.config.neo4j.uri_for("/db/data/transaction/1/commit") }

          let(:expires_string) { "Wed, 14 Dec 2016 10:39:44 GMT" }
          let(:expires) { Time.parse(expires_string) }

          let(:execution) { double "execution" }

          before do
            WebMock.disable_net_connect! allow_localhost: false

            allow(Execution).
              to receive(:new).
              and_return(execution)

            allow(execution).
              to receive(:flush!)

            allow(execution).
              to receive(:execute!).
              and_return(true)
          end

          after do
            Delfos.reset!
            WebMock.disable_net_connect! allow_localhost: true
          end

          describe ".execute!" do
            before do
              expect(described_class).
                to receive(:new).
                with(size: size).
                and_return(execution)

              expect(execution).
                to receive(:execute!).
                with(anything, params: {}).
                and_return(flushed)
            end

            context "with a non flushed response" do
              let(:flushed) { false }

              it "calls execute on the batch returning the url and expiry" do
                result = described_class.execute!(anything, params: {}, size: size)

                expect(result).to eq flushed
              end
            end

            context "with a flushed response" do
              let(:flushed) { true }

              it "calls execute on the batch returning the url and expiry" do
                result = described_class.execute!(anything, params: {}, size: size)

                expect(result).to eq flushed
              end
            end
          end
        end
      end
    end
  end
end
