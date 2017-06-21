# frozen_string_literal: true

require "json"
require "delfos/neo4j"
require "delfos/neo4j/call_site_query"

module Delfos
  module Neo4j
    module Offline
      class Importer
        attr_reader :filename

        def initialize(filename)
          @filename = filename
        end

        def perform
          each_line do |params, err|
            params = JSON.parse(params)

            execute(CallSiteQuery::BODY, params, err)
          end

          Neo4j.flush!
        end

        private

        def execute(query, params, err)
          Neo4j.execute(query, params)
        rescue Delfos::Neo4j::QueryExecution::InvalidQuery => e
          Delfos.logger.error e.message.to_s
          err.puts params
        end

        def each_line
          with_errors do |err|
            with_input do |f|
              f.each_line.lazy.each do |params|
                yield params, err
              end
            end
          end
        end

        def with_errors
          File.open("#{filename}.errors", "w") do |err|
            yield err
          end
        end

        def with_input
          File.open(filename, "r") do |f|
            yield f
          end
        end
      end
    end
  end
end
