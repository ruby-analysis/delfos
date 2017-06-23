# frozen_string_literal: true

require "json"
require "delfos/neo4j"
require "delfos/neo4j/call_site_query"
require "fileutils"

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
          Neo4j.execute_sync(query, params)
        rescue Delfos::Neo4j::QueryExecution::InvalidQuery => e
          @no_errors = false
          Delfos.logger.error e.message.to_s
          err.puts JSON.dump(params)
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
          @no_errors = true

          File.open(error_filename, "w") do |err|
            yield err
          end

          FileUtils.rm_rf error_filename if @no_errors
        end

        def error_filename
          "#{filename}.errors"
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
