require_relative "query_execution/http"

module Delfos
  module Neo4j
    module Schema
      class << self
        def constraints
          response = QueryExecution::Http.new(uri).get

          if response.code == "200"
            JSON.parse response.body
          else
            raise IOError.new uri, response
          end
        end

        private

        def uri
          @uri ||= URI.parse "#{Delfos.neo4j.url}/db/data/schema/constraint"
        end
      end
    end
  end
end

