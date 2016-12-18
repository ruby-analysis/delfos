# frozen_string_literal: true
module Delfos
  module Neo4j
    module Distance
      class CallSiteFetcher
        def self.perform
          Neo4j.execute_sync <<-QUERY
            MATCH
              (call_site:CallSite) - [:CALLS] -> (called:Method)

            RETURN
              call_site.file, id(call_site),
              called.file,    id(called)
          QUERY
        end
      end
    end
  end
end
