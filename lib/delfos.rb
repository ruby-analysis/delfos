# frozen_string_literal: true
require "delfos/version"
require "delfos/method_logging"
require "delfos/neo4j/informer"

module Delfos
  class << self
    def check_setup!
      raise "Delfos.setup! has not been called" unless neo4j_config && logger
    end

    def wipe_db!
      Delfos.setup!(application_directories: [])
      session = ::Neo4j::Session.open(*Delfos.neo4j_config)

      ::Neo4j::Session.query <<-QUERY
        MATCH (m)-[rel]->(n)
        DELETE m,rel,n
      QUERY
    end

    def reset!
      @application_directories = []
      @neo4j_config = nil
      @logger = nil
      remove_patching!
    end

    def remove_patching!
      load "delfos/remove_patching.rb"
      begin
        Delfos::Patching.instance_eval { @added_methods = nil }
      rescue
        nil
      end
    end

    def setup!(
      connection_type: :server_db,
      logger: Delfos::Neo4j::Informer.new,
      host:"http://localhost:7474",
      auth: { basic_auth: { username: "neo4j", password: "password" } },
      application_directories: nil)

      @application_directories = application_directories
      @logger = logger

      @neo4j_config = [connection_type, host, auth]

      perform_patching!
    end

    def perform_patching!
      load "delfos/perform_patching.rb"
    end

    attr_reader :application_directories, :neo4j_config
  end
end
