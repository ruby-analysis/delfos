ENV["NEO4J_URL"]      ||= "http://localhost:7476"
ENV["NEO4J_USERNAME"] ||= "neo4j"
ENV["NEO4J_PASSWORD"] ||= "password"

module DelfosSpecNeo4jHelpers
  extend self
  def wipe_db!
    Delfos.setup_neo4j!
    Delfos::Neo4j::QueryExecution.flush!

    perform_query "MATCH (m)-[rel]->(n) DELETE m, rel, n"
    perform_query "MATCH (m) DELETE m"

    #drop_constraint "Class", "name"
    #drop_constraint "ExecutionChain", "number"
  end

  def perform_query(q)
    require "delfos/neo4j/query_execution"
    Delfos::Neo4j::QueryExecution.execute_sync(q)
  end

  def drop_constraint(label, attribute)
    require "delfos/neo4j/query_execution/sync"
    #perform_query <<-QUERY
    #  DROP CONSTRAINT ON (c:#{label}) ASSERT c.#{attribute} IS UNIQUE
    #QUERY
  rescue Delfos::Neo4j::QueryExecution::InvalidQuery => e
    raise unless e.message["Unable to drop CONSTRAINT ON"]
  end
end


RSpec.configure do |c|
  c.include DelfosSpecNeo4jHelpers

  c.before(:suite) do
    begin
      DelfosSpecNeo4jHelpers.wipe_db!
    rescue Errno::ECONNREFUSED => e
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

    DelfosSpecNeo4jHelpers.perform_query "CREATE CONSTRAINT ON (c:Class) ASSERT c.name IS UNIQUE"
    DelfosSpecNeo4jHelpers.perform_query "CREATE CONSTRAINT ON (e:ExecutionChain) ASSERT e.number IS UNIQUE"
  end

  c.after(:suite) do
    require "delfos/neo4j/query_execution"
    Delfos::Neo4j::QueryExecution.flush!
  end
end
