# frozen_string_literal: true
require "json"
require "uri"
require_relative "http"

module Delfos
  module Neo4j
    module QueryExecution
      class Transactional
        attr_reader :query, :params

        def self.flush!(commit_url)
          Http.new(commit_url).post("{}")
        end

        def initialize(query, params, uri=nil)
          @query, @params, @uri = query, params, uri
        end

        def perform
          body = JSON.parse response.body

          if body["errors"].length.positive?
            raise InvalidQuery.new(body["errors"], query, params)
          end

          transaction_url = URI.parse header("location")
          commit_url      = URI.parse body["commit"]
          expires          = Time.parse body["transaction"]["expires"]

          [transaction_url, commit_url, expires]
        end

        private

        def header(name)
          response.each_header.to_a.find{|n,_| n == name}.last
        end

        def response
          @response ||= fetch
        end

        def fetch
          Http.new(uri).post(request_body)
        end

        def request_body
          {
            "statements": [{"statement": query , "parameters": params}]
          }.to_json
        end

        def uri
          @uri ||= URI.parse "#{Delfos.neo4j.url}/db/data/transaction"
        end
      end
    end
  end
end
