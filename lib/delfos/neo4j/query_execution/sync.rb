# frozen_string_literal: true
require "json"
require "uri"

require_relative "http"
require_relative "errors"

module Delfos
  module Neo4j
    module QueryExecution
      class Sync
        include HttpQuery

        def perform
          if errors?
            raise InvalidQuery.new(json["errors"], query, params)
          end

          strip_out_meta_data
        end

        private

        def strip_out_meta_data
          json["results"]
          &.first
          &.[]("data")
          &.map { |r| r["row"] }
        end

        def uri
          @uri ||= Delfos.neo4j.uri_for("/db/data/transaction/commit")
        end
      end
    end
  end
end
