# frozen_string_literal: true
require "spec_helper"
require_relative "execution"

module Delfos
  module Neo4j
    module Batch
      RSpec.describe Execution, "integration" do
        before do
          Delfos.setup_neo4j!
          WebMock.disable_net_connect! allow_localhost: true
        end

        describe ".execute!" do
          context "with 3 queries and a batch size of 3" do
            let(:size) { 3 }
            let(:node_names) { ["some name", "another name", "a final name"] }

            it do
              query = "MERGE (n:Node{name:{name}}) - [r:RELATIONSHIP] -> (o:Other)"

              node_names.each do |n|
                described_class.execute!(query, { name: n }, size)
              end

              result = perform_query("MATCH (n:Node) RETURN n.name")
              expect(result.flatten.sort).to eq ["some name", "another name", "a final name"].sort
            end
          end
        end
      end
    end
  end
end
