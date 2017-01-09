# frozen_string_literal: true
require "delfos/neo4j/query_execution/transactional"

module Delfos
  module Neo4j
    module Batch
      class Execution
        BATCH_MUTEX = Mutex.new

        class << self
          def execute!(query, params: {}, size: nil)
            batch = batch() || new_batch(size || 1_000)

            batch.execute!(query, params: params)
          end

          def new_batch(size)
            @batch = new(size: size)
          end

          def flush!
            batch&.flush!
          rescue
            reset!
          end

          def reset!
            self.batch = nil
          end

          attr_accessor :batch
        end

        def initialize(size:, clock: Time)
          @size                    = size
          @clock                   = clock
          @queries                 = []
          @expires                 = nil
          @commit_url              = nil
          @current_transaction_url = nil
        end

        attr_reader :size, :current_transaction_url, :commit_url, :expires, :queries

        def execute!(query, params: {}, retrying: false)
          queries.push([query, params]) unless retrying

          with_retry(retrying) do
            BATCH_MUTEX.synchronize do
              check_for_expiry!

              perform_query(query, params)
              flush_if_required!
            end
          end
        end

        def flush!
          return unless query_count.positive?
          return unless @commit_url
          QueryExecution::Transactional.commit!(@commit_url)

          reset!
        end

        def query_count
          queries.length
        end

        private

        def perform_query(query, params)
          transactional_query = QueryExecution::Transactional.new(query, params, url)
          transaction_url, @commit_url, @expires = transactional_query.perform
          @current_transaction_url ||= transaction_url # the transaction_url is only returned with the first request
        end

        def with_retry(retrying)
          yield
        rescue QueryExecution::ExpiredTransaction
          @retry_count ||= 0

          if retrying
            @retry_count += 1

            if @retry_count > 5
              @retry_count = 0
              Delfos.logger.error "Transaction expired - 5 retries failed aborting"
              raise
            end
          end

          Delfos.logger.error { "Transaction expired - retrying batch. #{query_count} queries retry_count: #{@retry_count} #{caller.inspect}" }
          reset_transaction!
          retry_batch!
        end

        def retry_batch!
          queries.each do |q, p|
            execute!(q, params: p, retrying: true)
          end
        end

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
            raise QueryExecution::ExpiredTransaction.new(@comit_url, "")
          end
        end

        def flush_if_required!
          check_for_expiry!

          flush! if batch_full? || expires_soon?
        end

        def batch_full?
          query_count >= size
        end

        def expires_soon?
          @expires && (@clock.now + 10 > @expires)
        end

        def reset!
          @queries = []
          reset_transaction!
        end

        def reset_transaction!
          @current_transaction_url = nil
          @commit_url = nil
          @expires = nil
        end
      end
    end
  end
end
