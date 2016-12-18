# frozen_string_literal: true
require "delfos/neo4j/query_execution/transactional"

module Delfos
  module Neo4j
    module Batch
      class Execution
        class ExpiredError < ::ArgumentError
        end

        BATCH_MUTEX = Mutex.new

        class << self
          def execute!(query, params = {}, size = nil)
            batch = @batch || new_batch(size || 1_000)

            batch.execute!(query, params)
          end

          def new_batch(size)
            @batch = new(size: size)
          end

          def flush!
            @batch&.flush!
          end

          def reset!
            @batch = nil
          end

          attr_writer :batch
        end

        def initialize(size:, clock: Time)
          @size                    = size
          @clock                   = clock
          @query_count             = 0
          @expires                 = nil
          @commit_url              = nil
          @current_transaction_url = nil
        end

        attr_reader :size, :query_count, :current_transaction_url, :commit_url, :expires

        def execute!(query, params = {})
          BATCH_MUTEX.synchronize do
            check_for_expiry!
            transactional_query = QueryExecution::Transactional.new(query, params, url)
            transaction_url, @commit_url, @expires = transactional_query.perform
            @current_transaction_url ||= transaction_url # the transaction_url is only returned with the first request

            flush_if_required!
          end
        end

        def flush!
          return unless @query_count.positive?
          return unless @commit_url
          QueryExecution::Transactional.flush!(@commit_url)
        ensure
          reset!
        end

        private

        def url
          return @commit_url if @commit_url && batch_full? || expires_soon?

          current_transaction_url || new_transaction_url
        end

        def new_transaction_url
          Delfos.neo4j.uri_for("/db/data/transaction")
        end

        def check_for_expiry!
          return unless @expires

          if @clock.now > @expires
            self.class.batch = nil
            raise ExpiredError
          end
        end

        def flush_if_required!
          check_for_expiry!
          @query_count += 1

          flush! if batch_full? || expires_soon?
        end

        def batch_full?
          query_count >= size
        end

        def expires_soon?
          @expires && (@clock.now + 2 > @expires)
        end

        def reset!
          @query_count = 0
          @current_transaction_url = nil
          @commit_url = nil
          @expires = nil
        end
      end
    end
  end
end
