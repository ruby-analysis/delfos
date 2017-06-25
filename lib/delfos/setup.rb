# frozen_string_literal: true

module Delfos
  module Setup
    extend self
    attr_accessor :neo4j

    def perform!
      require "delfos/method_trace"
      ::Delfos::MethodTrace.trace!
    end

    def disable!
      disable_tracepoint!

      reset_call_stack!
      reset_batch!

      reset_top_level_variables!
      reset_app_directories!
      reset_app_files!
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
      ignoring_undefined "Delfos::Neo4j::QueryExecution::Batch::Retryable" do |b|
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

    def reset_app_files!
      ignoring_undefined("Delfos::FileSystem::AppFiles", &:reset!)
    end

    def reset_top_level_variables!
      Delfos.config = nil
      Delfos.neo4j  = nil
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
