# frozen_string_literal: true
require "spec_helper"
require_relative "transactional"

module Delfos
  module Neo4j
    RSpec.describe Delfos::Neo4j::QueryExecution::Transactional do
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
        let(:transaction_url) { Delfos.neo4j.uri_for("/db/data/transaction/10") }
        let(:commit_url) { Delfos.neo4j.uri_for("/db/data/transaction/10/commit") }
        let(:expiry) { "Thu, 08 Dec 2016 11:13:49 +0000" }

        it do
          response = <<-RESPONSE
            {
              "commit" : #{commit_url.to_s.inspect},
              "results" : [ {
                "columns" : [ ],
                "data" : [  ]
              } ],
              "transaction" : {
                "expires" : "Thu, 08 Dec 2016 11:13:49 +0000"
              },
              "errors" : [ ]
            }
          RESPONSE

          stub_request(:post, Delfos.neo4j.uri_for("/db/data/transaction")).
            to_return(
              status: 200,
              body: response,
              headers: { location: transaction_url },
            )

          response_transaction_url, response_commit_url, response_expiry = described_class.new(some_query, some_params).perform

          expect(response_transaction_url).to eq transaction_url
          expect(response_commit_url).to eq commit_url
          expect(response_expiry).to eq Time.parse expiry
        end
      end
    end
  end
end
