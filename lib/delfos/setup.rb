# frozen_string_literal: true
module Delfos
  module Setup
    extend self
    attr_accessor :neo4j

    def perform!(call_site_logger: nil, application_directories: nil)
      self.application_directories = application_directories
      self.call_site_logger = call_site_logger

      perform_patching!
    end

    def application_directories=(dirs)
      dirs ||= %w(app lib)
      require "pathname"
      Delfos.application_directories = Array(dirs).map { |f| Pathname.new(File.expand_path(f.to_s)) }
    end

    def call_site_logger=(call_site_logger)
      unless call_site_logger
        setup_neo4j!

        require "delfos/neo4j/informer"
        call_site_logger = Delfos:: Neo4j::Informer.new
      end

      Delfos.call_site_logger = call_site_logger
    end

    def neo4j
      @neo4j ||= setup_neo4j!
    end

    def setup_neo4j!
      host     ||= ENV["NEO4J_HOST"]     || "http://localhost"
      port     ||= ENV["NEO4J_PORT"]     || "7474"
      username ||= ENV["NEO4J_USERNAME"] || "neo4j"
      password ||= ENV["NEO4J_PASSWORD"] || "password"

      Neo4jOptions.new(host, port, username, password)
    end

    Neo4jOptions = Struct.new(:host, :port, :username, :password) do
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

    def reset!
      if defined? Delfos::CallStack
        Delfos::CallStack.pop_until_top!
        Delfos::CallStack.reset!
      end

      if defined? Delfos::Neo4j::Batch::Execution && neo4j.username
        Delfos::Neo4j::Batch::Execution.flush!
        Delfos::Neo4j::Batch::Execution.reset!
      end

      # unstubbing depends upon MethodCache being still defined
      # so this order is important
      unstub_all!
      remove_cached_methods!

      remove_patching!

      Delfos.application_directories = []
      Delfos.method_logging = nil
      Delfos.call_site_logger = nil

      self.neo4j = nil
    end

    def unstub_all!
      if defined? Delfos::Patching::MethodOverride
        if Delfos::Patching::MethodOverride.respond_to?(:unstub_all!)
          Delfos::Patching::MethodOverride.unstub_all!
        end
      end
    end

    def remove_cached_methods!
      if defined? Delfos::MethodLogging::MethodCache
        Delfos::MethodLogging::MethodCache.instance_eval { @instance = nil }
      end
    end

    def remove_patching!
      load "delfos/patching/basic_object_remove.rb"
    end

    def perform_patching!
      load "delfos/patching/basic_object.rb"
    end
  end
end
