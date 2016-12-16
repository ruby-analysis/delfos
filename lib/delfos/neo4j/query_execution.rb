# frozen_string_literal: true
require_relative "query_execution/sync"
require_relative "query_execution/transactional"
require_relative "batch_execution"
require_relative "schema"

module Delfos
  module Neo4j
    module QueryExecution
      def self.execute_sync(query, params={})
        Sync.new(query, params).perform
      end

      def self.execute(query, params={})
        BatchExecution.execute!(query, params)
      end

      def self.flush!
        BatchExecution.flush!
      end

      def self.fetch_schema
        Schema.constraints
      end
    end
  end
end
