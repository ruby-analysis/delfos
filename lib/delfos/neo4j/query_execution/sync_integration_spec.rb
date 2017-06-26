# frozen_string_literal: true

require "spec_helper"
require_relative "sync"

module Delfos
  module Neo4j
    module QueryExecution
      RSpec.describe Sync, "Integration" do
        before do
          WebMock.allow_net_connect!
        end

        describe "#perform" do
          it do
            described_class.new(write_query, params).perform
            result = described_class.new(read_query, params).perform

            expect(result).to eq [["some name", 2, "other name"]]
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
