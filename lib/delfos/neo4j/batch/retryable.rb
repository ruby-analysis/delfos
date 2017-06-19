# frozen_string_literal: true

require_relative "execution"

module Delfos
  module Neo4j
    module Batch
      class Retryable
        class << self
          MUTEX = Mutex.new

          def reset!
            MUTEX.synchronize do
              Thread.current[:_delfos__retryable_batch] = nil
            end
          end

          def ensure_instance(size: nil)
            MUTEX.synchronize do
              Thread.current[:_delfos__retryable_batch] ||= new(size: size || 1_000)
            end
          end

          def execute!(query, params: {}, size: nil)
            ensure_instance(size: size).execute!(query, params: params)
          end

          def flush!
            ensure_instance&.flush!
            reset!
          end
        end

        attr_reader :size, :queries, :execution
        attr_accessor :retry_count

        def initialize(size:)
          @size = size
          reset!
        end

        def execute!(query, params: {}, retrying: false)
          queries.push([query, params]) unless retrying

          with_retry(retrying) do
            flushed = execution.execute!(query, params: params)

            reset! if flushed
          end
        end

        def flush!
          execution.flush!
          reset!
        end

        private

        def with_retry(already_retrying)
          yield
        rescue QueryExecution::ExpiredTransaction
          check_retry_limit! if already_retrying

          retry_batch!
        end

        def check_retry_limit!
          self.retry_count += 1

          return if self.retry_count <= 5

          self.retry_count = 0
          Delfos.logger.error "Transaction expired - 5 retries failed aborting"
          raise
        end

        def retry_batch!
          Delfos.logger.error do
            sleep 1 + (retry_count**1.2)
            "Transaction expired - retrying batch. #{queries.count} queries retry_count: #{retry_count}"
          end

          new_execution

          queries.each { |q, p| execute!(q, params: p, retrying: true) }

          Delfos.logger.error { "Batch retry successful" }
        end

        def reset!
          @queries = []
          new_execution
          @retry_count = 0
        end

        def new_execution
          @execution = Execution.new(size: size)
        end
      end
    end
  end
end
