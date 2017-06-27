# frozen_string_literal: true

require "delfos/neo4j/call_site_query"
require "json"

module Delfos
  module Neo4j
    module Offline
      class CallSiteLogger
        attr_writer :count

        def log(call_site, stack_uuid, step_number)
          query = CallSiteQuery.new(call_site, stack_uuid, step_number)

          file.puts JSON.dump(query.params)
          self.count += 1
          file.flush if (count % 100).zero?
        end

        def reset!
          finish!
        end

        def finish!
          return if Delfos.offline_query_filename.nil? || file.closed?

          file.flush
          file.close
          @file = nil
        end

        def count
          @count ||= 0
        end

        private

        def file
          @file ||= File.open(Delfos.offline_query_filename, "a")
        end
      end
    end
  end
end
