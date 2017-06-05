# frozen_string_literal: true
require_relative "call_stack_query"
require_relative "call_site_query"

module Delfos
  module Neo4j
    class CallSiteLogger
      def save_call_stack(call_sites, execution_number)
        perform Neo4j::CallStackQuery, call_sites, execution_number
      end

      def log(call_site, called_code)
        perform CallSiteQuery, call_site, called_code
      end

      private

      def perform(klass, *args)
        q = klass.new(*args)

        Neo4j.execute(q.query, q.params)
      end
    end
  end
end
