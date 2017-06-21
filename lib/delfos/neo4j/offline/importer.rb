# frozen_string_literal: true

require "json"
require "delfos/neo4j"

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
            f.each_line.lazy.each do |line|
              query, params = line.split("\t")
              Delfos::Neo4j.execute_sync(query, JSON.parse(params))
            end
          end
        end
      end
    end
  end
end
