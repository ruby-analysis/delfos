# frozen_string_literal: true

require "delfos/setup"
require "delfos/config"
require "forwardable"

module Delfos
  class << self
    extend Forwardable

    attr_writer :neo4j

    def_delegators :config,
      :application_directories,
      :batch_size,
      :call_site_logger,
      :ignored_files,
      :logger,
      :max_query_size,
      :offline_query_saving,
      :offline_query_filename

    def config
      @config ||= Delfos::Config.new
    end

    def configure
      yield config
    end

    def clear_config!
      @config = nil
    end

    def start!
      Setup.perform!
    end

    def import_offline_queries(filename)
      require "delfos/neo4j/offline/importer"
      Neo4j::Offline::Importer.new(filename).perform
    end

    def include_file?(file)
      require "delfos/file_system"
      FileSystem.include_file?(file)
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
        config.call_site_logger.finish!
      else
        flush!
        update_distance!
      end
      disable!
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
  end
end
