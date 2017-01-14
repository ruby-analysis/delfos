# frozen_string_literal: true
require_relative "execution"

module Delfos
  module Neo4j
    module Batch
      class RetryableExecution
        class << self
          def execute!(query, params: {}, size: nil)
            new_instance(size).execute!(query, params: params)
          end

          def new_instance(size=nil)
            self.instance ||= new(size: size || 1_000)
          end

          def flush!
            instance&.flush!
          end

          attr_accessor :instance
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

        def with_retry(retrying)
          yield
        rescue QueryExecution::ExpiredTransaction
          check_retry_limit! if retrying

          Delfos.logger.error do
            "Transaction expired - retrying batch. #{queries.count} queries retry_count: #{retry_count}"
          end

          retry_batch!

          Delfos.logger.error do
            "Batch retry successful"
          end
        end

        def check_retry_limit!
          self.retry_count += 1

          return if self.retry_count <= 5

          self.retry_count = 0
          Delfos.logger.error "Transaction expired - 5 retries failed aborting"
          raise
        end

        def retry_batch!
          queries.each { |q, p| execute!(q, params: p, retrying: true) }
        end

        def reset!
          @queries = []
          @execution = new_execution
          @retry_count = 0
        end

        def new_execution
          Execution.new(size: size)
        end
      end
    end
  end
end
