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
          File.open(filename, "r") do |f|
            f.each_line.lazy.each do |params|
              params = JSON.parse(params)
              query = CallSiteQuery::Body.new(params).to_s
              Neo4j.execute_sync(query, params)
            end
          end
        end
      end
    end
  end
end
