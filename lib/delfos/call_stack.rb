# frozen_string_literal: true
require_relative "neo4j"
require_relative "call_stack/stack"

module Delfos
  module CallStack
    CALL_STACK_MUTEX = Mutex.new
    extend self

    def reset!
      CALL_STACK_MUTEX.synchronize do
        Thread.current[:_delfos__call_stack] = nil
      end
    end

    def stack
      CALL_STACK_MUTEX.synchronize do
        Thread.current[:_delfos__call_stack] ||= Stack.new(on_empty: method(:save!))
      end
    end

    def push(method_object)
      stack.push(method_object)
    end

    def pop
      stack.pop
    end

    def pop_until_top!
      stack.pop_until_top!
    end

    def save!(call_sites, execution_number)
      Delfos::MethodLogging.save_call_stack(call_sites, execution_number)
    end
  end
end
