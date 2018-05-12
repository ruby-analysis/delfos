# frozen_string_literal: true

ENV["NEO4J_HOST"]     ||= "http://localhost"
ENV["NEO4J_PORT"]     ||= "8476"
ENV["NEO4J_USERNAME"] ||= "neo4j"
ENV["NEO4J_PASSWORD"] ||= "password"

module DelfosSpecNeo4jHelpers
  extend self

  def wipe_db!
    require "delfos/neo4j"

    perform_query "MATCH (m)-[rel]->(n) DELETE m, rel, n"
    perform_query "MATCH (m) DELETE m"
  end

  def perform_query(query)
    Delfos::Neo4j.execute_sync(query)
  end
end

# rubocop:disable Metrics/BlockLength
RSpec.configure do |c|
  c.include DelfosSpecNeo4jHelpers

  c.before(:suite) do
    require "delfos/neo4j/query_execution/errors"
    begin
      Delfos.config = nil
      Delfos.new_config
      DelfosSpecNeo4jHelpers.wipe_db!
    rescue *Delfos::Neo4j::QueryExecution::HTTP_ERRORS => e
      puts <<-ERROR
       ***************************************
       ***************************************
       ***************************************

       Failed to connect to Neo4j:
         #{e}

       Neo4j config:
         #{Delfos.config.neo4j}

       Start Neo4j or set the following environment variables:
         NEO4J_HOST
         NEO4J_PORT
         NEO4J_USERNAME
         NEO4J_PASSWORD

       ***************************************
       ***************************************
       ***************************************
      ERROR
      exit(-1)
    end

    Delfos::Neo4j.ensure_schema!
    DelfosSpecs.reset_config!
  end
end
# rubocop:enable Metrics/BlockLength
