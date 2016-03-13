# frozen_string_literal: true
require "delfos/version"
require "delfos/method_logging"

module Delfos
  class << self
    def check_setup!
      raise "Delfos.setup! has not been called" unless neo4j_config && logger
    end

    def reset!
      @application_directories = []
      @neo4j_config = nil
      @logger = nil
      remove_patching!
    end

    def remove_patching!
      load "delfos/remove_patching.rb"
      begin
        Delfos::Patching.instance_eval { @added_methods = nil }
      rescue
        nil
      end
    end

    def setup!(
      connection_type: :server_db,
      logger: STDOUT,
      host:"http://localhost:7474",
      auth: { basic_auth: { username: "neo4j", password: "password" } },
      application_directories: nil)

      @application_directories = application_directories
      @logger = logger

      @neo4j_config = [connection_type, host, auth]

      perform_patching!
    end

    def perform_patching!
      load "delfos/perform_patching.rb"
    end

    attr_reader :application_directories, :neo4j_config
  end
end
