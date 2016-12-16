# frozen_string_literal: true
require "delfos"
require "net/http"

module Delfos
  module Neo4j
    module QueryExecution
      class Http
        attr_reader :uri

        def initialize(uri)
          @uri = uri
        end

        def post(body)
          response(build_post(body))
        end

        def get
          response(build_get)
        end

        private

        def response(request)
          http = Net::HTTP.new(uri.host, uri.port)

          http.request(request)
        rescue *ERRORS => e
          raise ConnectionError.new(e)
        end

        ERRORS = [
          EOFError,
          Errno::ECONNRESET,
          Errno::EINVAL,
          Net::HTTPBadResponse,
          Net::HTTPHeaderSyntaxError,
          Net::ProtocolError,
          Timeout::Error
        ]


        def build_post(body)
          build_request("Post") do |request|
            add_headers(request)

            request.body = body
          end
        end

        def build_get
          build_request("Get") do |request|
            add_headers(request)
          end
        end

        def build_request(type)
          Net::HTTP.const_get(type).new(uri.request_uri).tap do |request|
            yield request
          end
        end

        def add_headers(request)
          request.initialize_http_header({"Accept" => "application/json; charset=UTF-8"})
          request.basic_auth(Delfos.neo4j.username, Delfos.neo4j.password)
          request.content_type = "application/json"
        end
      end
    end
  end
end
