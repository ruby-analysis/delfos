# frozen_string_literal: true

require "json"
require "uri"
require "time"

require_relative "http"
require_relative "http_query"

module Delfos
  module Neo4j
    module QueryExecution
      class Transactional
        include HttpQuery

        def self.commit!(url)
          response = Http.new(url).post({ statements: [] }.to_json)

          check_for_error(url, response)

          response.code == "200"
        end

        VALID_RESPONSE_MATCHER = /\A2\d\d\z/

        def self.check_for_error(uri, response)
          return if response.code[VALID_RESPONSE_MATCHER]

          raise ExpiredTransaction.new(uri, response) if response.code == "404"

          raise InvalidCommit.new(uri, response)
        end

        def perform
          self.class.check_for_error(uri, response)

          raise InvalidQuery.new(json["errors"], query, params) if errors?

          transaction_url = URI.parse  header("location") if header("location")
          commit_url      = URI.parse  json["commit"]     if json["commit"]
          expires         = Time.parse json["transaction"]["expires"] if json["transaction"]

          [transaction_url, commit_url, expires]
        end

        private

        def header(name)
          response.each_header.to_a.find { |n, _| n == name }&.last
        end

        def uri
          @uri ||= Delfos.neo4j.uri_for("/db/data/transaction")
        end
      end

      class InvalidCommit < IOError
        def initialize(commit_url, response)
          super ["URL:", commit_url, "response:", response].join("\n  ")
        end
      end

      class ExpiredTransaction < InvalidCommit
      end
    end
  end
end
