# frozen_string_literal: true

require "spec_helper"
require_relative "sync"

module Delfos
  module Neo4j
    module QueryExecution
      RSpec.describe Sync do
        before do
          Delfos.setup_neo4j!
          WebMock.disable_net_connect! allow_localhost: false
        end

        after do
          WebMock.allow_net_connect!
        end

        describe "#perform" do
          let(:some_params) { {} }
          let(:some_query) { "some query" }

          context "with a successful response" do
            before do
              data = [{ "row" => ["some name", 2, "other name"] }]
              body = { "results" => [{ "columns" => ["n.name", "r.rel_attribute", "o.name"], "data" => data }], "errors" => [] }.to_json

              stub_request(:post, Delfos.neo4j.uri_for("/db/data/transaction/commit")).
                to_return(
                  status: 200,
                  body: body,
                  headers: {},
                )
            end

            it do
              described_class.new(write_query, params).perform
              result = described_class.new(read_query, params).perform

              expect(result).to eq [["some name", 2, "other name"]]
            end
          end

          context "with an error response" do
            before do
              body = { "results" => [], "errors" => [{ code: "some error", message: "some message" }] }.to_json

              stub_request(:post, Delfos.neo4j.uri_for("/db/data/transaction/commit")).
                to_return(
                  status: 200,
                  body: body,
                  headers: {},
                )
            end

            it do
              expect(-> { described_class.new(some_query, some_params).perform }).
                to raise_error InvalidQuery
            end
          end

          context "with an EOFError" do
            before do
              allow(Net::HTTP).to receive(:new).and_raise EOFError
            end

            it do
              expect(-> { described_class.new(some_query, some_params).perform }).to raise_error ConnectionError
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
