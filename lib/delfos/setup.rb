# frozen_string_literal: true

module Delfos
  module Setup
    extend self
    attr_accessor :neo4j

    def perform!(call_site_logger: nil, application_directories: nil)
      self.application_directories = application_directories
      self.call_site_logger = call_site_logger

      require "delfos/method_trace"
      ::Delfos::MethodTrace.trace!
    end

    def application_directories=(dirs)
      dirs ||= %w[app lib]
      require "pathname"
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

      require "delfos/neo4j/call_site_logger"
      Delfos:: Neo4j::CallSiteLogger.new
    end

    def disable!
      disable_tracepoint!

      reset_call_stack!
      reset_batch!

      reset_top_level_variables!
      reset_app_directories!
    end

    def disable_tracepoint!
      require "delfos/method_trace"
      ::Delfos::MethodTrace.disable!
    end

    def reset_call_stack!
      ignoring_undefined("Delfos::CallStack") do |k|
        k.pop_until_top!
        k.reset!
      end
    end

    def reset_batch!
      Delfos.batch_size = nil

      ignoring_undefined "Delfos::Neo4j::Batch::Retryable" do |b|
        begin
          with_rescue { b.flush! }
        ensure
          b.instance = nil
        end
      end
    end

    def reset_app_directories!
      ignoring_undefined("Delfos::FileSystem::AppDirectories", &:reset!)
    end

    def reset_top_level_variables!
      Delfos.neo4j                   = nil
      Delfos.logger                  = nil
      Delfos.application_directories = nil
      Delfos.call_site_logger        = nil
      Delfos.max_query_size          = nil
      @call_site_logger              = nil
      Delfos.neo4j                   = nil
    end

    # This method allows resetting in between every spec.  So we avoid load
    # order issues in cases where we have not run particular specs that require
    # and define these constants
    def ignoring_undefined(k)
      o = Object.const_get(k)
      yield(o)
    rescue NameError => e
      raise unless e.message[k]
    end

    def with_rescue
      yield
    rescue Delfos::Neo4j::QueryExecution::ExpiredTransaction
      puts # no-op
    end
  end
end
