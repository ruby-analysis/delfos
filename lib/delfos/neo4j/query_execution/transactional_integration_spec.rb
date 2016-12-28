# frozen_string_literal: true
require "spec_helper"
require_relative "transactional"

module Delfos
  module Neo4j
    module QueryExecution
      RSpec.describe Transactional do
        before do
          WebMock.allow_net_connect!
          Delfos.setup_neo4j!
        end

        describe "#perform" do
          context "success" do
            after do
              described_class.flush!(commit_url)
            end

            let(:transactional_query) { described_class.new(write_query, params).perform }
            let(:transaction_url) { transactional_query[0] }
            let(:commit_url)      { transactional_query[1] }
            let(:response_expiry) { transactional_query[2] }


            it "returns a transaction url" do
              expect(transaction_url).to be_a URI
              expect(transaction_url.to_s).to match Delfos.neo4j.url
              expect(transaction_url.path).to match %r{/db/data/transaction/\d+}
            end

            it "returns a commit url" do
              expect(commit_url.to_s).to match Delfos.neo4j.url
              expect(commit_url.path).to match %r{/db/data/transaction/\d+/commit}
            end

            it "returns an expiry time" do
              expect(response_expiry).to be_a Time
              expect(response_expiry > Time.now ).to be_truthy
            end
          end

          context "timeout" do
            let(:transactional_query) { described_class.new(write_query, params) }

            let(:bomb) do
              bomb = double "Time bomb"

              allow(bomb).to receive(:post).
                and_return Net::HTTPNotFound.new(anything, "404", 123)

              bomb
            end

            before do
              expect(Http).to receive(:new).and_return bomb
            end

            it do
              expect(->{transactional_query.perform}).to raise_error ExpiredTransaction
            end
          end
        end

        def write_query
          strip_whitespace <<-QUERY
            MERGE (n:SomeNode{name:{node_name}})
              -   [r:SOME_RELATIONSHIP{rel_attribute:2}]
              ->  (o:OtherNode{name:"other name"})
          QUERY
        end

        def params
          { node_name: "some name" }
        end

        def read_query
          <<-QUERY
            MATCH (n:SomeNode{name:{node_name}})
              -   [r:SOME_RELATIONSHIP]
              ->  (o:OtherNode)

            RETURN
              n.name,
              r.rel_attribute,
              o.name
          QUERY
        end
      end
    end
  end
end
