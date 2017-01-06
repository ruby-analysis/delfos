# frozen_string_literal: true
module Delfos
  module Setup
    extend self
    attr_accessor :neo4j

    def perform!(call_site_logger: nil, application_directories: nil)
      self.application_directories = application_directories
      self.call_site_logger = call_site_logger

      perform_patching!
    end

    def application_directories=(dirs)
      dirs ||= %w(app lib)
      Delfos.application_directories = Array(dirs).map { |f| Pathname.new(f.to_s).expand_path }
    end

    def call_site_logger
      @call_site_logger ||= default_call_site_logger
    end

    def call_site_logger=(call_site_logger)
      @call_site_logger = call_site_logger || default_call_site_logger
    end

    def default_call_site_logger
      Delfos.setup_neo4j!

      require "delfos/neo4j/informer"
      Delfos:: Neo4j::Informer.new
    end

    def reset!
      if defined? Delfos::CallStack
        Delfos::CallStack.pop_until_top!
        Delfos::CallStack.reset!
      end

      if defined? Delfos::Neo4j::Batch::Execution
        begin
          Delfos::Neo4j::Batch::Execution.flush!
        rescue
          Delfos::Neo4j::QueryExecution::ExpiredTransaction
        end

        Delfos::Neo4j::Batch::Execution.reset!
      end

      # unstubbing depends upon MethodCache being still defined
      # so this order is important
      unstub_all!
      remove_cached_methods!

      remove_patching!

      Delfos::MethodLogging.reset! if defined?(Delfos::MethodLogging) && Delfos::MethodLogging.respond_to?(:reset!)

      Delfos.neo4j                   = nil
      Delfos.logger                  = nil
      Delfos.application_directories = nil
      Delfos.call_site_logger        = nil
      @call_site_logger              = nil
      Delfos.neo4j                   = nil
    end

    def unstub_all!
      return unless defined? Delfos::Patching::Unstubber

      Delfos::Patching::Unstubber.unstub_all!
    end

    def remove_cached_methods!
      return unless defined? Delfos::Patching::MethodCache

      Delfos::Patching::MethodCache.reset!
    end

    def remove_patching!
      load "delfos/patching/basic_object_remove.rb"
    end

    def perform_patching!
      load "delfos/patching/basic_object.rb"
    end
  end
end
