ENV["NEO4J_HOST"]     ||= "http://localhost"
ENV["NEO4J_PORT"]     ||= "7476"
ENV["NEO4J_USERNAME"] ||= "neo4j"
ENV["NEO4J_PASSWORD"] ||= "password"

module DelfosSpecNeo4jHelpers
  extend self

  def wipe_db!
    require "delfos/neo4j"
    Delfos.setup_neo4j!
    Delfos::Neo4j.flush!

    perform_query "MATCH (m)-[rel]->(n) DELETE m, rel, n"
    perform_query "MATCH (m) DELETE m"
  end

  def perform_query(q)
    Delfos::Neo4j.execute_sync(q)
  end
end


RSpec.configure do |c|
  c.include DelfosSpecNeo4jHelpers

  c.before(:suite) do
    require "delfos/neo4j/query_execution/errors"
    begin
      DelfosSpecNeo4jHelpers.wipe_db!
    rescue *Delfos::Neo4j::QueryExecution::HTTP_ERRORS, Delfos::Neo4j::QueryExecution::ConnectionError => e
      Delfos.logger.error "*" * 80
      Delfos.logger.error "*" * 80
      Delfos.logger.error "*" * 80
      Delfos.logger.error "Failed to connect to Neo4j:"
      Delfos.logger.error Delfos.neo4j
      Delfos.logger.error "Start Neo4j or set the following environment variables:"
      Delfos.logger.error "  NEO4J_HOST"
      Delfos.logger.error "  NEO4J_PORT"
      Delfos.logger.error "  NEO4J_USERNAME"
      Delfos.logger.error "  NEO4J_PASSWORD"
      Delfos.logger.error "*" * 80
      Delfos.logger.error "*" * 80
      Delfos.logger.error "*" * 80
    end

    Delfos::Neo4j.ensure_schema!
  end

  c.after(:suite) do
    require "delfos/neo4j"
    Delfos::Neo4j.flush!
  end
end
