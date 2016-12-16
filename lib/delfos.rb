# frozen_string_literal: true

module Delfos
  class << self
    attr_writer :application_directories

    def setup!(logger: nil,
               neo4j_url: nil,
               neo4j_username: nil,
               neo4j_password: nil,
               application_directories: nil)
      application_directories ||= %w(app lib)

      unless logger
        require "delfos/neo4j/informer"
        logger = Delfos:: Neo4j::Informer.new
      end

      require "pathname"
      @application_directories = Array(application_directories).map { |f| Pathname.new(File.expand_path(f.to_s)) }
      @logger = logger

      if defined? Delfos::Neo4j::Informer
        setup_neo4j!(neo4j_url, neo4j_username, neo4j_password)
      end

      perform_patching!
    end

    def setup_neo4j!(url = nil, username = nil, password = nil)
      url      ||= ENV["NEO4J_URL"]      || "http://localhost:7474"
      username ||= ENV["NEO4J_USERNAME"] || "neo4j"
      password ||= ENV["NEO4J_PASSWORD"] || "password"

      @neo4j = Neo4jOptions.new(url, username, password)
    end


    def check_setup!
      raise "Delfos.setup! has not been called" unless neo4j_config && logger
    end

    def reset!
      if defined? Delfos::Neo4j::BatchExecution && neo4j.username
        Delfos::Neo4j::BatchExecution.flush!
        Delfos::Neo4j::BatchExecution.reset!
      end

      if defined? Delfos::ExecutionChain
        Delfos::ExecutionChain.reset!
      end

      @application_directories = []
      @method_logging = nil
      @neo4j = nil
      @logger = nil
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
