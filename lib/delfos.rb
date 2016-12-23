# frozen_string_literal: true
require "delfos/setup"

module Delfos
  class << self
    attr_accessor :application_directories, :call_site_logger
    attr_writer :logger, :neo4j

    def call_site_logger
      @call_site_logger ||= Delfos::Setup.call_site_logger
    end

    def logger
      @logger ||= default_logger
    end

    def setup!(logger: nil, call_site_logger: nil, application_directories: nil)
      self.logger = logger if logger
      Delfos::Setup.perform!(call_site_logger: call_site_logger, application_directories: application_directories)
    end

    def neo4j
      setup_neo4j!
    end

    def setup_neo4j!
      @neo4j ||= Delfos::Neo4j.config
    end

    def reset!
      Delfos::Setup.reset!
    end

    def default_logger
      require "logger"
      Logger.new(STDOUT)
    end
  end
end
