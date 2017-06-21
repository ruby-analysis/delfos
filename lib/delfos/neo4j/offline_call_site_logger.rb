# frozen_string_literal: true

require_relative "call_site_query"

module Delfos
  module Neo4j
    class OfflineCallSiteLogger
      attr_writer :count

      def log(call_site, stack_uuid, step_number)
        query = CallSiteQuery.new(call_site, stack_uuid, step_number)

        execute(query.query, query.params)
      end

      def execute(query, params)
        file.puts format(query, params)

        self.count += 1
        file.flush if (count % 100).zero?
      end

      def finish!
        return if file.closed?

        file.flush
        file.close
      end

      def count
        @count ||= 0
      end

      private

      def format(query, params)
        query = query.
                tr("\n", " ").
                gsub(/\ +/, " ")

        params = params.to_json

        "#{query}\t#{params}\tnot_imported"
      end

      def file
        @file ||= File.open(Delfos.offline_query_filename, "a")
      end
    end
  end
end
