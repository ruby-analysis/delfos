# frozen_string_literal: true

require "delfos/setup"

module Delfos
  class << self
    attr_accessor :application_directories,
      :offline_query_saving,
      :offline_query_filename

    attr_writer :logger, :neo4j, :batch_size, :max_query_size

    # rubocop:disable Metrics/ParameterLists
    def setup!(
      logger: nil,
      call_site_logger: nil,
      application_directories: nil,
      batch_size: nil,
      max_query_size: nil,
      offline_query_saving: nil
    )
      # rubocop:enable Metrics/ParameterLists
      self.logger         = logger
      self.batch_size     = batch_size
      self.max_query_size = max_query_size

      Setup.perform!(
        call_site_logger: call_site_logger,
        application_directories: application_directories,
        offline_query_saving: offline_query_saving,
      )
    end

    def import_offline_queries(filename)
      require "delfos/neo4j/offline/importer"
      Neo4j::Offline::Importer.new(filename).perform
    end

    def batch_size
      @batch_size ||= 100
    end

    def max_query_size
      @max_query_size ||= 10_000
    end

    def include_file?(file)
      require "delfos/file_system"
      FileSystem.include_file?(file)
    end

    attr_writer :call_site_logger

    def call_site_logger
      @call_site_logger ||= Delfos::Setup.default_call_site_logger
    end

    def logger
      @logger ||= default_logger
    end

    def neo4j
      setup_neo4j!
    end

    def setup_neo4j!
      require "delfos/neo4j"
      @neo4j ||= Neo4j.config
    end

    def finish!
      if offline_query_saving
        Delfos.call_site_logger.finish!
      else
        flush!
        update_distance!
        disable!
      end
    end

    def update_distance!
      require "delfos/neo4j"
      Neo4j.update_distance!
    end

    def flush!
      require "delfos/neo4j"
      Neo4j.flush!
    end

    def disable!
      Setup.disable!
    end

    def default_logger
      require "logger"

      Logger.new(STDOUT).tap do |l|
        l.level = Logger::ERROR
      end
    end
  end
end
