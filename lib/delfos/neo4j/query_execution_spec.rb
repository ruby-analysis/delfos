require "spec_helper"
require_relative "query_execution"

module Delfos
  module Neo4j
    RSpec.describe Delfos::Neo4j::QueryExecution do
      describe ".execute" do
        def perform_requests!
          body = strip_whitespace <<-QUERY
            MERGE (n:SomeNode{name:{node_name}})
              -   [r:SOME_RELATIONSHIP{rel_attribute:2}]
              ->  (o:OtherNode{name:"other name"})
          QUERY

          described_class.execute body, {node_name: "some name"}


          described_class.execute <<-QUERY, {node_name: "some name"}
            MATCH (n:SomeNode{name:{node_name}})
              -   [r:SOME_RELATIONSHIP]
              ->  (o:OtherNode)

            RETURN
              n.name,
              r.rel_attribute,
              o.name
          QUERY
        end

        context "with actual connection" do
          before do
            WebMock.allow_net_connect!
            Delfos.setup_neo4j!
          end

          it do
            result = perform_requests!

            expect(result).to eq [["some name", 2, "other name"]]
          end
        end

        context "without connecting" do
          before do
            Delfos.setup_neo4j!
            WebMock.disable_net_connect! allow_localhost: false
          end

          after do
            WebMock.allow_net_connect!
          end

          context "with a successful response" do
            before do
              data = [{"row"=>["some name", 2, "other name"]}]
              body = {"results"=>[{"columns"=>["n.name", "r.rel_attribute", "o.name"], "data"=>data}], "errors"=>[]}.to_json

              stub_request(:post, "http://localhost:7476/db/data/transaction/commit").
                to_return(
                  :status  => 200,
                  :body    => body,
                  :headers => {}
              )
            end

            it do
              result = perform_requests!

              expect(result).to eq [["some name", 2, "other name"]]
            end
          end

          context "with an error response" do
            before do
              body = {"results"=>[], "errors"=>[{code: "some error", message: "some message"}]}.to_json

              stub_request(:post, "http://localhost:7476/db/data/transaction/commit").
                to_return(
                  :status  => 200,
                  :body    => body,
                  :headers => {}
              )
            end

            it do
              expect(->{perform_requests!}).to raise_error QueryExecution::InvalidQuery
            end
          end

          context "with an EOFError" do
            before do
              allow(Net::HTTP).to receive(:new).and_raise EOFError
            end

            it  do
              expect(->{perform_requests!}).to raise_error QueryExecution::ConnectionError
            end
          end
        end
      end
    end
  end
end
