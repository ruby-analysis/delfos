# frozen_string_literal: true

module Delfos
  class Config
    attr_reader :application_directories,
      :ignored_files,
      :offline_query_saving,
      :offline_query_filename

    attr_accessor :batch_size,
      :call_site_logger,
      :ignored_files,
      :logger,
      :max_query_size

    def initialize
      @application_directories = default_application_directories
      @batch_size = default_batch_size
      @call_site_logger = default_call_site_logger
      @ignored_files = default_ignored_files
      @logger = default_logger
      @max_query_size = default_max_query_size
      @offline_query_saving = default_offline_query_saving
      @offline_query_filename = default_offline_query_filename
    end

    def application_directories=(dirs)
      require "pathname"
      @application_directories = Array(dirs).map { |f| Pathname.new(f.to_s).expand_path }
    end

    def ignored_files=(files)
      require "pathname"
      @ignored_files = Array(files).map { |f| Pathname.new(f.to_s).expand_path }
    end

    def offline_query_saving=(bool)
      @offline_query_saving = bool
      @call_site_logger = default_call_site_logger
    end

    def offline_query_filename=(path)
      @offline_query_filename = path || default_offline_query_filename
    end

    private

    def default_application_directories
      require "pathname"
      %w[app lib].map { |f| Pathname.new(f.to_s).expand_path }
    end

    def default_batch_size
      100
    end

    def default_call_site_logger
      if @offline_query_saving
        require "delfos/neo4j/offline/call_site_logger"
        Delfos:: Neo4j::Offline::CallSiteLogger.new
      else
        Delfos.setup_neo4j!
        require "delfos/neo4j/live/call_site_logger"
        Delfos:: Neo4j::Live::CallSiteLogger.new
      end
    end

    def default_ignored_files
      []
    end

    def default_logger
      require "logger"
      Logger.new(STDOUT).tap do |l|
        l.level = Logger::ERROR
      end
    end

    def default_max_query_size
      10_000
    end

    def default_offline_query_saving
      false
    end

    def default_offline_query_filename
      @offline_query_saving ? "delfos_query_parameters.json" : nil
    end
  end
end
