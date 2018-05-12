# frozen_string_literal: true

require "forwardable"

require "delfos/config"
require "delfos/method_trace"
require "delfos/neo4j"

module Delfos
  class << self
    extend Forwardable

    def_delegators :config,
      :batch_size,
      :call_site_logger,
      :logger,
      :max_query_size,
      :offline_query_saving,
      :offline_query_filename

    attr_accessor :config

    def start!
      ::Delfos::MethodTrace.enable!
    end

    def finish!
      ::Delfos::MethodTrace.disable!

      config.call_site_logger.finish!
    end

    def reset!
      Delfos.config&.call_site_logger&.reset!
    end

    def configure
      new_config

      yield config if block_given?
    end

    def import_offline_queries(filename)
      Neo4j.import_offline_queries(filename)
    end

    def include_file?(file)
      config&.include?(file)
    end

    def update_distance!
      Neo4j.update_distance!
    end

    def new_config
      self.config ||= Delfos::Config.new
    end
  end
end
