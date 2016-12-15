require_relative "query_execution/transactional"

module Delfos
  module Neo4j
    class BatchExecution
      class ExpiredError < ::ArgumentError
      end

      BATCH_MUTEX = Mutex.new

      class << self
        def execute!(query, params={}, size: 1_000)
          batch(size: size).execute!(query, params)
        end

        def batch(size:)
          @batch ||= new(size: size)
        end

        def reset!
          @batch = nil
        end

        attr_writer :batch
      end

      def initialize(size:, clock: Time)
        @size = size
        @query_count = 0
        @clock = clock
      end

      attr_accessor :size, :query_count
      attr_reader :transaction_url, :commit_url, :expires

      def execute!(query, params={})
        BATCH_MUTEX.synchronize do
          check_for_expiry!
          @transaction_url, @commit_url, @expires = QueryExecution::Transactional.new(query, params, url).perform

          flush_if_required!

          [@transaction_url, @commit_url, @expires]
        end
      end

      private

      def url
        @transaction_url || URI.parse("#{Delfos.neo4j.url}/db/data/transaction/")
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

        if query_count >= size || expires_soon?
          flush!
        end
      end

      def expires_soon?
        @clock.now + 2 > @expires
      end

      def flush!
        QueryExecution::Transactional.flush!(@commit_url)
        reset!
      end

      def reset!
        @query_count = 0
        @transaction_url = nil
        @commit_url = nil
        @expires = nil
      end
    end
  end
end


