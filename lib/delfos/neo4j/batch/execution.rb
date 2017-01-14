# frozen_string_literal: true
require "delfos/neo4j/query_execution/transactional"

module Delfos
  module Neo4j
    module Batch
      class Execution
        attr_reader :size, :current_transaction_url, :commit_url, :expires, :query_count

        def initialize(size:, clock: Time)
          @size                    = size
          @clock                   = clock
          reset!
        end

        def execute!(query, params: {})
          check_for_expiry!

          perform_query(query, params)
          flush_if_required!
        end

        def flush!
          return unless query_count.positive?
          return unless @commit_url
          QueryExecution::Transactional.commit!(@commit_url)

          reset!
        end

        private

        def perform_query(query, params)
          transactional_query = QueryExecution::Transactional.new(query, params, url)
          transaction_url, @commit_url, @expires = transactional_query.perform
          @current_transaction_url ||= transaction_url # the transaction_url is only returned with the first request
          @query_count += 1
        end

        def url
          return @commit_url if @commit_url && batch_full? || expires_soon?

          current_transaction_url || new_transaction_url
        end

        def new_transaction_url
          Delfos.neo4j.uri_for("/db/data/transaction")
        end

        def check_for_expiry!
          return if @expires.nil? || (@clock.now <= @expires)

          raise QueryExecution::ExpiredTransaction.new(@comit_url, "")
        end

        def flush_if_required!
          check_for_expiry!

          if batch_full? || expires_soon?
            flush!
            return true
          end

          false
        end

        def batch_full?
          query_count >= size
        end

        def expires_soon?
          @expires && (@clock.now + 10 > @expires)
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
