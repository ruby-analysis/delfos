ENV["NEO4J_URL"]      ||= "http://localhost:7476"
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
    rescue *Delfos::Neo4j::QueryExecution::HTTP_ERRORS => e
      puts "*" * 80
      puts "*" * 80
      puts "*" * 80
      puts "Failed to connect to Neo4j:"
      puts Delfos.neo4j
      puts "Start Neo4j or set the following environment variables:"
      puts "  NEO4J_URL"
      puts "  NEO4J_USERNAME"
      puts "  NEO4J_PASSWORD"
      puts "*" * 80
      puts "*" * 80
      puts "*" * 80
    end


    Delfos::Neo4j.ensure_schema!
  end

  c.after(:suite) do
    require "delfos/neo4j"
    Delfos::Neo4j.flush!
  end
end
