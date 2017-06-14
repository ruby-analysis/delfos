# frozen_string_literal: true

require "delfos/setup"

module Delfos
  class << self
    attr_accessor :application_directories
    attr_writer :logger, :neo4j

    def setup!(logger: nil, call_site_logger: nil, application_directories: nil)
      self.logger = logger if logger
      Delfos::Setup.perform!(call_site_logger: call_site_logger, application_directories: application_directories)
    end

    def include_file?(file)
      require "delfos/file_system"
      FileSystem.include_file?(file)
    end

    def call_site_logger
      Delfos::Setup.call_site_logger
    end

    def call_site_logger=(call_site_logger)
      Delfos::Setup.call_site_logger = call_site_logger
    end

    def logger
      @logger ||= default_logger
    end

    def neo4j
      setup_neo4j!
    end

    def setup_neo4j!
      require "delfos/neo4j"
      @neo4j ||= Delfos::Neo4j.config
    end

    def flush!
      Delfos::Neo4j.flush!
    end

    def finish!
      flush!
      Delfos::Neo4j.update_distance!
      disable!
    end

    def disable!
      Delfos::Setup.disable!
    end

    def default_logger
      require "logger"
      Logger.new(STDOUT)
    end
  end
end
