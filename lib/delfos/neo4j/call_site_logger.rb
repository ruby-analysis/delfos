# frozen_string_literal: true

require_relative "call_stack_query"
require_relative "call_site_query"
require_relative "file_system_logger"

module Delfos
  module Neo4j
    class CallSiteLogger
      def initialize(output_path: nil)
        @persistence = if output_path
                         FileSystemLogger.new(output_path: output_path)
                       else
                         Neo4j
        end
      end

      def finish!
        @persistence.finish!
      end

      def save_call_stack(call_sites, execution_number)
        perform CallStackQuery, call_sites, execution_number
      end

      def log(call_site)
        perform CallSiteQuery, call_site
      end

      private

      def perform(klass, *args)
        q = klass.new(*args)

        @persistence.execute(q.query, q.params)
      end
    end
  end
end
