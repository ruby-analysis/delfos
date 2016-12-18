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

        def self.flush!(commit_url)
          response = Http.new(commit_url).post({statements: []}.to_json)

          unless response.code == "200"
            raise InvalidCommit.new(commit_url, response)
          end
        end

        def perform
          if errors?
            raise InvalidQuery.new(json["errors"], query, params)
          end

          transaction_url = URI.parse  header("location") if header("location")
          commit_url      = URI.parse  json["commit"]     if json["commit"]
          expires         = Time.parse json["transaction"]["expires"]

          [transaction_url, commit_url, expires]
        end

        private

        def header(name)
          response.each_header.to_a.find{|n,_| n == name}&.last
        end

        def uri
          @uri ||= Delfos.neo4j.uri_for("/db/data/transaction")
        end
      end

      class InvalidCommit < IOError
        def initialize(commit_url, response)
          super ["URL:", commit_url, response].join("\n")
        end
      end
    end
  end
end
