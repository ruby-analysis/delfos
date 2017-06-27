# frozen_string_literal: true

require "forwardable"
require_relative "config/inclusion"

module Delfos
  class Config
    attr_reader :offline_query_saving, :offline_query_filename

    attr_accessor :batch_size,
      :call_site_logger,
      :logger,
      :max_query_size

    extend Forwardable

    def_delegators :inclusion,
      :included_directories, :included_files, :include=, :include, :include?,
      :excluded_directories, :excluded_files, :exclude=, :exclude, :exclude?

    def initialize
      @batch_size              = default_batch_size
      @call_site_logger        = default_call_site_logger
      @logger                  = default_logger
      @max_query_size          = default_max_query_size
      @offline_query_saving    = default_offline_query_saving
      @offline_query_filename  = default_offline_query_filename
    end

    def offline_query_saving=(bool)
      @offline_query_saving = bool
      @call_site_logger = default_call_site_logger
    end

    def offline_query_filename=(path)
      @offline_query_filename = path || default_offline_query_filename
    end

    def neo4j
      setup_neo4j!
    end

    private

    def inclusion
      @inclusion ||= Inclusion.new
    end

    def default_batch_size
      100
    end

    def default_call_site_logger
      if @offline_query_saving
        require "delfos/neo4j/offline/call_site_logger"
        Delfos:: Neo4j::Offline::CallSiteLogger.new
      else
        setup_neo4j!
        require "delfos/neo4j/live/call_site_logger"
        Delfos:: Neo4j::Live::CallSiteLogger.new
      end
    end

    def setup_neo4j!
      require "delfos/neo4j"
      @neo4j ||= Neo4j.config
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
      return unless @offline_query_saving

      FileUtils.mkdir "./tmp"

      "./tmp/delfos_query_parameters.json"
    end
  end
end
