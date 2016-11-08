# frozen_string_literal: true
require_relative "neo4j/execution_persistence"

module Delfos
  class ExecutionChain
    EXECUTION_CHAIN_MUTEX = Mutex.new

    def self.reset!
      EXECUTION_CHAIN_MUTEX.synchronize do
        Thread.current[:_delfos__execution_chain] = nil
      end
    end

    def self.execution_chain
      EXECUTION_CHAIN_MUTEX.synchronize do
        Thread.current[:_delfos__execution_chain] ||= new
      end
    end

    def self.push(method_object)
      execution_chain.push(method_object)
    end

    def self.pop
      execution_chain.pop
    end

    def push(method_object)
      call_sites.push(method_object)
      self.stack_depth += 1

      self.execution_count += self.stack_depth == 1 ? 1 : 0
    end

    def pop
      popping_empty_stack! if self.stack_depth.zero?

      self.stack_depth -= 1

      save_and_reset!  if self.stack_depth.zero?
    end

    def stack_depth
      @stack_depth ||= 0
    end

    def execution_count
      @execution_count ||= 0
    end

    def call_sites
      @call_sites ||= []
    end

    def step_count
      call_sites.length
    end

    attr_writer :stack_depth, :step_count, :execution_count, :call_sites

    private

    class PoppingEmptyStackError < StandardError
    end

    def popping_empty_stack!
      raise PoppingEmptyStackError
    end

    def save_and_reset!
      Neo4j::ExecutionPersistence.save!(self) if call_sites.length.positive?
      self.call_sites = []
    end
  end
end
