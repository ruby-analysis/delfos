# frozen_string_literal: true
require "spec_helper"

require "delfos/neo4j"

require_relative "execution"

module Delfos
  module Neo4j
    module Batch
      RSpec.describe Execution do
        let(:size)      { 10 }
        let(:batch)     { described_class.new(size: size, clock: clock) }
        let(:execution) { double("") }
        let(:transaction_url) { Delfos.neo4j.uri_for("/db/data/transaction/1") }
        let(:commit_url) { Delfos.neo4j.uri_for("/db/data/transaction/1/commit") }

        let(:expires_string) { "Wed, 14 Dec 2016 10:39:44 GMT" }
        let(:expires) { Time.parse(expires_string) }
        let(:now)       { Time.parse("Wed, 14 Dec 2016 10:33:44 GMT") }
        let(:clock)     { double "clock", now: now }

        let(:transactional) { double "transactional" }

        let(:body) do
          <<-RESPONSE
          {
            "commit" : #{commit_url.inspect},
            "results" : [ {
              "columns" : [ ],
              "data" : [  ]
            } ],
            "transaction" : {
              "expires" : #{expires_string.inspect}
            },
            "errors" : [ ]
          }
          RESPONSE
        end

        before do
          Delfos.setup_neo4j!
          WebMock.disable_net_connect! allow_localhost: false

          allow(QueryExecution::Transactional).
            to receive(:new).
            and_return(transactional)

          allow(transactional).
            to receive(:perform).
            and_return([transaction_url, commit_url, expires])
        end

        after do
          WebMock.disable_net_connect! allow_localhost: true
        end

        describe ".execute!" do
          before do
            allow(described_class).
              to receive(:new).
              with(size: size).
              and_return(batch)
          end

          it "calls execute on the batch returning the url and expiry" do
            expect(batch).
              to receive(:execute!).
              with(anything, params: {}).
              and_return([transaction_url, commit_url, expires])

            returned_url, commit_url, returned_expiry = described_class.execute!(anything, params: {}, size: size)

            expect(returned_url)    .to eq transaction_url
            expect(commit_url)      .to eq commit_url
            expect(returned_expiry) .to eq expires
          end
        end

        describe "#execute!" do
          context "with some queries executed" do
            before do
              allow(QueryExecution::Transactional).
                to receive(:commit!)

              Array.new(executions) { batch.execute!(anything, params: {}) }
            end

            context "with fewer queries than the batch size" do
              let(:size) { 5 }
              let(:executions) { 4 }

              it do
                expect(QueryExecution::Transactional).
                  not_to have_received(:commit!)
              end

              it "keeps track of the query count" do
                expect(batch.query_count).to eq executions
              end
            end

            context "just before commiting" do
              let(:size) { 6 }
              let(:executions) { 5 }

              it "has an accurate query count" do
                expect(batch.query_count).to eq 5
              end

              it do
                expect(QueryExecution::Transactional).
                  not_to have_received(:commit!)
              end
            end

            context "with one more execution than the batch size" do
              let(:size) { 8 }
              let(:executions) { 9 }

              it "resets the count" do
                expect(batch.query_count).to eq 1
              end

              it do
                expect(QueryExecution::Transactional).
                  to have_received(:commit!).
                  with(commit_url)
              end

              it "starts the next batch" do
                batch.execute!(anything, params: {})
                expect(batch.query_count).to eq 2
              end
            end
          end

          context "beyond the expiry time" do
            let(:now)  { expires + 20 }

            it "resets the batch" do
              Delfos.logger.level = Logger::FATAL
              expect(-> { 2.times { batch.execute!(anything, params: anything) } }).to raise_error QueryExecution::ExpiredTransaction
              Delfos.logger.level = Logger::ERROR

              new_batch = described_class.new_batch(size)

              expect(new_batch).not_to eq batch
              expect(new_batch.query_count).to eq 0
              expect(new_batch.current_transaction_url).to eq nil
              expect(new_batch.commit_url).to eq nil
              expect(new_batch.expires).to eq nil
            end
          end

          context "with a transaction that expires soon" do
            let(:now) { expires - 1.5 }

            before do
              allow(QueryExecution::Transactional).to receive(:commit!)
            end

            it "commits next transaction" do
              batch.execute!(anything, params: {})
              expect(QueryExecution::Transactional).to have_received(:commit!).with commit_url
            end
          end
        end
      end
    end
  end
end
