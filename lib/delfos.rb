# frozen_string_literal: true
require "delfos/neo4j/informer"

module Delfos
  class << self
    attr_writer :application_directories

    def check_setup!
      raise "Delfos.setup! has not been called" unless neo4j_config && logger
    end

    def wipe_db!
      Delfos.setup_neo4j!

      require "delfos/neo4j/query_execution"

      Delfos::Neo4j::QueryExecution.execute <<-QUERY
        MATCH (m)-[rel]->(n)
        DELETE m,rel,n
      QUERY

      Delfos::Neo4j::QueryExecution.execute <<-QUERY
        MATCH (m)
        DELETE m
      QUERY

      drop_constraint "Class", "name"
      drop_constraint "ExecutionChain", "number"
    end

    def drop_constraint(label, attribute)
      Delfos::Neo4j::QueryExecution.execute <<-QUERY
        DROP CONSTRAINT ON (c:#{label}) ASSERT c.#{attribute} IS UNIQUE
      QUERY
    rescue Delfos::Neo4j::QueryExecution::ExecutionError => e
      raise unless e.message["Unable to drop CONSTRAINT ON"]
    end

    def reset!
      @application_directories = []
      @method_logging = nil
      @neo4j = nil
      @logger = nil

      if defined? Delfos::ExecutionChain
        Delfos::ExecutionChain.reset!
      end

      # unstubbing depends upon AddedMethods being still defined
      # so this order is important
      unstub_all!
      remove_added_methods!

      remove_patching!
    end

    def unstub_all!
      if defined? Delfos::Patching::MethodOverride

        if Delfos::Patching::MethodOverride.respond_to?(:unstub_all!)
          Delfos::Patching::MethodOverride.unstub_all!
        end
      end
    end

    def remove_added_methods!
      if defined? Delfos::MethodLogging::AddedMethods
        Delfos::MethodLogging::AddedMethods.instance_eval { @instance = nil }
      end
    end

    def remove_patching!
      load "delfos/patching/basic_object_remove.rb"
    end

    def setup!(logger: Delfos::Neo4j::Informer.new,
               neo4j_url: nil,
               neo4j_username: nil,
               neo4j_password: nil,
               application_directories: nil)
      application_directories ||= %w(app lib)

      @application_directories = if application_directories.is_a?(Proc)
                                   application_directories
                                 else
                                   Array(application_directories).map { |f| Pathname.new(File.expand_path(f.to_s)) }
                                 end

      @logger = logger

      setup_neo4j!(neo4j_url, neo4j_username, neo4j_password)

      perform_patching!
    end

    def setup_neo4j!(url = nil, username = nil, password = nil)
      url ||= ENV["NEO4J_URL"] || "http://localhost:7474"
      username ||= ENV["NEO4J_USERNAME"] || "neo4j"
      password ||= ENV["NEO4J_PASSWORD"] || "password"
      @neo4j = Neo4jOptions.new(url, username, password)
    end

    def perform_patching!
      load "delfos/patching/basic_object.rb"
    end

    attr_reader :neo4j

    Neo4jOptions = Struct.new(:url, :username, :password) do
      def to_s
        "  url: #{url}\n  username: #{username}\n  password: #{password}"
      end
    end

    attr_reader :application_directories, :neo4j_host, :neo4j_username, :neo4j_password
  end
end
