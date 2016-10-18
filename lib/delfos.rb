# frozen_string_literal: true
require "delfos/version"
require "delfos/method_logging"
require "delfos/neo4j/query_execution"
require "delfos/neo4j/informer"

module Delfos
  class << self
    def check_setup!
      raise "Delfos.setup! has not been called" unless neo4j_config && logger
    end

    def wipe_db!
      Delfos.setup!(application_directories: [])
      Delfos::Neo4j::QueryExecution.execute <<-QUERY
        MATCH (m)-[rel]->(n)
        DELETE m,rel,n
      QUERY

      Delfos::Neo4j::QueryExecution.execute <<-QUERY
        MATCH (m)
        DELETE m
      QUERY
    end

    def reset!
      @application_directories = []
      @neo4j_host = nil
      @neo4j_username = nil
      @neo4j_password = nil
      @logger = nil
      remove_patching!
    end

    def remove_patching!
      Delfos::Patching.instance_eval { @added_methods = nil }

      load "delfos/patching/remove_patching.rb"
    end

    def setup!(
      logger: Delfos::Neo4j::Informer.new,
      neo4j_url: ENV["NEO4J_URL"] || "http://localhost:7474",
      neo4j_username: ENV["NEO4J_USERNAME"] || "neo4j",
      neo4j_password: ENV["NEO4J_PASSWORD"] || "password",
      application_directories: nil)

      @application_directories = if application_directories.is_a?(Proc)
        application_directories
      else
        Array(application_directories).map{|f| Pathname.new(File.expand_path(f.to_s))}
      end

      @logger = logger

      @neo4j = Neo4jOptions.new(neo4j_url, neo4j_username, neo4j_password)

      perform_patching!
    end

    attr_reader :neo4j

    class Neo4jOptions < Struct.new(:url, :username, :password)
      def to_s
        "  url: #{url}\n  username: #{username}\n  password: #{password}"
      end
    end

    def perform_patching!
      load "delfos/patching/perform_patching.rb"
    end

    attr_reader :application_directories, :neo4j_host, :neo4j_username, :neo4j_password
  end
end
