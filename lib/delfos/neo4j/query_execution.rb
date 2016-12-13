# frozen_string_literal: true
require "delfos"
require "json"
require "net/http"
require "uri"

module Delfos
  module Neo4j
    module QueryExecution
      class << self
        def execute(query, params={})
          parse_response(*response_for(query, params))
        end

        private

        def parse_response(result, query, params)
          result = JSON.parse result.body

          if result["errors"].length.positive?
            raise InvalidQuery.new(result["errors"], query, params)
          end

          strip_out_meta_data(result)
        end

        def strip_out_meta_data(result)
          result["results"]
            &.first
            &.[]("data")
            &.map { |r| r["row"] }
        end

        def response_for(query, params)
          request = request_for(query, params)
          response = perform(request)

          [response, query, params]
        end

        HTTP_ERRORS = [
          EOFError,
          Errno::ECONNRESET,
          Errno::EINVAL,
          Net::HTTPBadResponse,
          Net::HTTPHeaderSyntaxError,
          Net::ProtocolError,
          Timeout::Error
        ]

        def perform(request)
          http = Net::HTTP.new(uri.host, uri.port)
          http.request(request)
        rescue *HTTP_ERRORS => e
          raise ConnectionError.new(e)
        end

        def request_for(query, params)
          build_request({
            "statements": [{"statement": query , "parameters": params}]
            }.to_json
          )
        end

        def build_request(body)
          Net::HTTP::Post.new(uri.request_uri).tap do |request|
            request.basic_auth(Delfos.neo4j.username, Delfos.neo4j.password)
            request.content_type = "application/json"

            request.body = body
          end
        end

        def uri
          @uri ||= URI.parse "#{Delfos.neo4j.url}/db/data/transaction/commit"
        end
      end

      class InvalidQuery  < IOError
        def initialize(errors, query, params)
          message = errors.map do |e|
            e.select{|k,_| %w(code message).include?(k) }.inspect
          end.join("\n")

          super [message, {query: query, params: params.to_json}.to_json].join("\n\n")
        end
      end

      class ConnectionError < IOError
      end
    end
  end
end
