# frozen_string_literal: true
require_relative "neo4j/call_site_logger"
require_relative "neo4j/query_execution/sync"
require_relative "neo4j/batch/retryable_execution"
require_relative "neo4j/schema"
require_relative "neo4j/distance/update"

module Delfos
  module Neo4j
    extend self

    def execute_sync(query, params = {})
      QueryExecution::Sync.new(query, params).perform
    end

    def execute(query, params = {})
      Batch::RetryableExecution.execute!(query, params: params)
    end

    def flush!
      Batch::RetryableExecution.flush!
    end

    def ensure_schema!
      Schema.ensure_constraints!(
        "Class"     => "name",
        "CallStack" => "number",
      )
    end

    def update_distance!
      Distance::Update.new.perform
    end

    def config
      host     ||= ENV["NEO4J_HOST"]     || "http://localhost"
      port     ||= ENV["NEO4J_PORT"]     || "7476"
      username ||= ENV["NEO4J_USERNAME"] || "neo4j"
      password ||= ENV["NEO4J_PASSWORD"] || "password"

      Neo4jConfig.new(host, port, username, password)
    end

    Neo4jConfig = Struct.new(:host, :port, :username, :password) do
      def url
        "#{host}:#{port}"
      end

      def uri_for(path)
        URI.parse("#{url}#{path}")
      end

      def to_s
        "  host: #{host}\n  port: #{port}\n  username: #{username}\n  password: #{password}"
      end
    end
  end
end
