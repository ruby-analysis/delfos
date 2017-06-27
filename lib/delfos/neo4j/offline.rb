# frozen_string_literal: true

require_relative "offline/importer"

module Delfos
  module Neo4j
    module Offline
      def self.import_queries(filename)
        Importer.new(filename).perform
      end
    end
  end
end
