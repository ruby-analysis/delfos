# frozen_string_literal: true
require_relative "query_execution/sync"

module Delfos
  module Neo4j
    module QueryExecution
      def self.execute(query, params={})
        Sync.new(query, params).perform
      end

    end
  end
end
