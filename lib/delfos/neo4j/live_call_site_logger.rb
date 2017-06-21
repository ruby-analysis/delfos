# frozen_string_literal: true

require_relative "call_site_query"

module Delfos
  module Neo4j
    class LiveCallSiteLogger
      def log(call_site, stack_uuid, step_number)
        q = CallSiteQuery.new(call_site, stack_uuid, step_number)

        Neo4j.execute(q.query, q.params)
      end
    end
  end
end
