# frozen_string_literal: true
require_relative "neo4j/informer"
require_relative "neo4j/query_execution/sync"
require_relative "neo4j/batch/execution"
require_relative "neo4j/schema"
require_relative "neo4j/distance/update"

module Delfos
  module Neo4j
    def self.execute_sync(query, params={})
      QueryExecution::Sync.new(query, params).perform
    end

    def self.execute(query, params={})
      Batch::Execution.execute!(query, params)
    end

    def self.flush!
      Batch::Execution.flush!
    end

    def self.ensure_schema!
      Schema.ensure_constraints!(
        "Class"          => "name",
        "ExecutionChain" => "number"
      )
    end

    def self.update_distance!
      Distance::Update.new.perform
    end
  end
end
