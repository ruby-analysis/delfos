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
      if BasicObject.respond_to?(:_delfos_undefine_methods!)
        load "delfos/remove_patching.rb"
        BasicObject.instance_eval { undef _delfos_undefine_methods! }
        BasicObject.instance_eval { @@_delfos_added_methods = nil }
      end
    end

    def setup!(connection_type: :server_db,
      host:"http://localhost:7474",
      auth: { basic_auth: { username: "neo4j", password: "password" } },
      application_directories: nil)

      @application_directories = application_directories

      @neo4j_config = [connection_type, host, auth]

      perform_patching!
    end

    def perform_patching!
      unless BasicObject.respond_to?(:_delfos_undefine_methods!)
        load "delfos/perform_patching.rb"
      end
    end

    attr_reader :application_directories, :neo4j_config
  end
end
