# frozen_string_literal: true

require_relative "call_site_query"

module Delfos
  module Neo4j
    class OfflineCallSiteLogger
      def log(call_site, stack_uuid, step_number)
        query = CallSiteQuery.new(call_site, stack_uuid, step_number)

        @file_system_logger.execute(query.query, query.params)
      end

      def file_system_logger
        @file_system_logger ||= FileSystemLogger.new("delfos_query_output.cypher")
      end
    end
  end
end
