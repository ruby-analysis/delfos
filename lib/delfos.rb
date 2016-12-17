# frozen_string_literal: true
require "delfos/setup"

module Delfos
  class << self
    attr_accessor :application_directories, :call_site_logger
    attr_writer :method_logging, :logger

    def method_logging
      @method_logging ||= ::Delfos::MethodLogging
    end

    def logger
      @logger ||= default_logger
    end

    def setup!(logger: nil, call_site_logger: nil, application_directories: nil)
      self.logger = logger if logger
      Delfos::Setup.perform!(call_site_logger: call_site_logger, application_directories: application_directories)
    end

    def setup_neo4j!
      Delfos::Setup.setup_neo4j!
    end

    def neo4j
      Delfos::Setup.neo4j
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
