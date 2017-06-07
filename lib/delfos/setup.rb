# frozen_string_literal: true
module Delfos
  module Setup
    extend self
    attr_accessor :neo4j

    def perform!(call_site_logger: nil, application_directories: nil)
      self.application_directories = application_directories
      self.call_site_logger = call_site_logger

      require "delfos/method_trace"
      ::Delfos::MethodTrace.trace(Delfos.application_directories)
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

      require "delfos/neo4j/call_site_logger"
      Delfos:: Neo4j::CallSiteLogger.new
    end

    def reset!
      reset_call_stack!
      reset_parser_cache!
      reset_batch!

      reset_unstubbing_and_method_cache!

      remove_patching!
      reset_method_logging!

      reset_top_level_variables!
    end

    def reset_call_stack!
      ignoring_undefined("Delfos::CallStack") do |k|
        k.pop_until_top!
        k.reset!
      end
    end

    def reset_parser_cache!
      ignoring_undefined("Delfos::Patching::Parameters::FileParserCache", &:reset!)
    end

    def reset_batch!
      ignoring_undefined "Delfos::Neo4j::Batch::Retryable" do |b|
        begin
          with_rescue { b.flush! }
        ensure
          b.instance = nil
        end
      end
    end

    def reset_unstubbing_and_method_cache!
      # unstubbing depends upon MethodCache being still defined
      # so this order is important
      unstub_all!
      remove_cached_methods!
    end

    def reset_method_logging!
      ignoring_undefined("Delfos::MethodLogging", &:reset!)
    end

    def reset_top_level_variables!
      Delfos.neo4j                   = nil
      Delfos.logger                  = nil
      Delfos.application_directories = nil
      Delfos.call_site_logger        = nil
      @call_site_logger              = nil
      Delfos.neo4j                   = nil
    end

    def ignoring_undefined(k)
      o = Object.const_get(k)
      yield(o)
    rescue NameError => e
      raise unless e.message[k]
    end

    def with_rescue
      yield
    rescue Delfos::Neo4j::QueryExecution::ExpiredTransaction
    end

    def unstub_all!
      ignoring_undefined("Delfos::Patching::Unstubber", &:unstub_all!)
    end

    def remove_cached_methods!
      ignoring_undefined("Delfos::Patching::MethodCache", &:reset!)
    end

    def remove_patching!
      load "delfos/patching/basic_object_remove.rb"
    end

    def perform_patching!
      load "delfos/patching/basic_object.rb"
    end
  end
end
