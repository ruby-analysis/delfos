# frozen_string_literal: true
require "spec_helper"
require_relative "transactional"

module Delfos
  module Neo4j
    RSpec.describe Delfos::Neo4j::QueryExecution::Transactional do
      before do
        WebMock.allow_net_connect!
        Delfos.setup_neo4j!
      end

      after do
        described_class.flush!(response_url)
      end

      let(:transactional_query) { described_class.new(write_query, params).perform }
      let(:response_url) { transactional_query.first }
      let(:response_expiry) { transactional_query.last }

      describe "#perform" do
        it do
          expect(response_url).to be_a URI
          expect(response_url.to_s).to match Delfos.neo4j.url
          expect(response_url.path).to match %r{/db/data/transaction/\d+}

          expect(response_expiry).to be_a Time
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
