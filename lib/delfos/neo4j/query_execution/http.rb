# frozen_string_literal: true
require "delfos"
require "net/http"

module Delfos
  module Neo4j
    module QueryExecution
      class Http
        def initialize(uri)
          @uri = uri
        end

        attr_reader :uri

        def post(body)
          response(build_request(body))
        end

        private

        ERRORS = [
          EOFError,
          Errno::ECONNRESET,
          Errno::EINVAL,
          Net::HTTPBadResponse,
          Net::HTTPHeaderSyntaxError,
          Net::ProtocolError,
          Timeout::Error
        ]

        def response(request)
          http = Net::HTTP.new(uri.host, uri.port)

          http.request(request)
        rescue *ERRORS => e
          raise ConnectionError.new(e)
        end

        def build_request(body)
          Net::HTTP::Post.new(uri.request_uri).tap do |request|

            request.initialize_http_header({"Accept" => "application/json; charset=UTF-8"})
            request.basic_auth(Delfos.neo4j.username, Delfos.neo4j.password)
            request.content_type = "application/json"

            request.body = body
          end
        end
      end
    end
  end
end
