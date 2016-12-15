# frozen_string_literal: true
require "json"
require "uri"

require_relative "http"
require_relative "errors"

module Delfos
  module Neo4j
    module QueryExecution
      class Sync
        attr_reader :query, :params

        def initialize(query, params={})
          @query, @params = query, params
        end

        def perform
          if errors?
            raise InvalidQuery.new(json["errors"], query, params)
          end

          strip_out_meta_data(json)
        end

        private

        def errors?
          json["errors"].length.positive?
        end

        def json
          JSON.parse response.body
        end

        def strip_out_meta_data(result)
          result["results"]
          &.first
          &.[]("data")
          &.map { |r| r["row"] }
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
          @uri ||= URI.parse "#{Delfos.neo4j.url}/db/data/transaction/commit"
        end
      end
    end
  end
end
