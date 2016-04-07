module Delfos
  class ExecutionChain
    METHOD_CHAIN_MUTEX = Mutex.new

    def self.reset!
      METHOD_CHAIN_MUTEX.synchronize do
        Thread.current[:_delfos__execution_chain__method_chain] = nil
      end
    end

    def self.method_chain
      METHOD_CHAIN_MUTEX.synchronize do
        Thread.current[:_delfos__execution_chain__method_chain] ||= new
      end
    end

    def self.push(method_object)
      method_chain.push(method_object)
    end

    def self.pop
      method_chain.pop
    end

    def push(method_object)
      self.stack_depth += 1
      self.step_count += 1

      self.execution_count += self.stack_depth == 1 ? 1 : 0
    end

    def pop
      self.stack_depth -= 1 unless stack_depth == 0
      self.step_count = 0 if self.stack_depth == 0
    end

    def stack_depth
      @stack_depth ||= 0
    end

    def step_count
      @step_count ||= 0
    end

    def execution_count
      @execution_count ||= 0
    end

    private

    attr_writer :stack_depth, :step_count, :execution_count
  end
end
