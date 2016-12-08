# frozen_string_literal: true
require "delfos"
require "json"
require "net/http"
require "uri"

module Delfos
  module Neo4j
    module QueryExecution
      class ExecutionError  < IOError
        def initialize(response, query, params)
          message = response.inspect

          super [message, query, params.to_json].join("\n\n    ")
        end
      end

      class << self
        def execute(query, params={})
          return unless query.length.positive?

          parse_response(*response_for(query, params))
        end

        private


        def parse_response(result, query, params)
          result = JSON.parse result.body

          if result["errors"].length.positive?
            raise ExecutionError.new(result["errors"], query, params)
          end

          strip_out_meta_data(result)
        end

        def strip_out_meta_data(result)
          results = result["results"]

          if results
            result = results.first
            if result
              data = result["data"]
              data &.map { |r| r["row"] }
            end
          end
        end

        def response_for(query, params)
          request = request_for(query, params)
          http = Net::HTTP.new(uri.host, uri.port)

          response = http.request(request)
          [response, query, params]
        end

        def request_for(query, params)
          build_request do
            "{\"statements\": [{\"statement\": #{query.inspect} , \"parameters\": #{params.to_json}}]}"
          end
        end

        def build_request
          Net::HTTP::Post.new(uri.request_uri).tap do |request|
            request.basic_auth(Delfos.neo4j.username, Delfos.neo4j.password)
            request.content_type = "application/json"

            request.body = yield
          end
        end

        def uri
          @uri ||= URI.parse "#{Delfos.neo4j.url}/db/data/transaction/commit"
        end
      end
    end
  end
end
