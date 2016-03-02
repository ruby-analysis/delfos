require "delfos/version"
require "delfos/method_logging"

module Delfos
  class << self
    def check_setup!
      raise "Delfos.setup! has not been called" unless neo4j_config && application_directories
    end
    
    def setup!(connection_type: :server_db,
               host:'http://localhost:7474',
               auth: {basic_auth: { username: 'neo4j', password: 'password'}},
               application_directories: nil)

      @application_directories = application_directories

      @neo4j_config = [ connection_type, host, auth]

      #Don't monkey patch object until we have any directories defined
      require_relative "delfos/perform_patching"
    end

    attr_reader :application_directories, :neo4j_config
  end
end
