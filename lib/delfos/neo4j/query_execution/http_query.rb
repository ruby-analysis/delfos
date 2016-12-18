module Delfos
  module Neo4j
    module QueryExecution
      module HttpQuery
        def self.included(base)
          base.instance_eval do
            attr_reader :query, :params
          end
        end

        def initialize(query, params, uri=nil)
          @query, @params, @uri = query, params, uri
        end

        private

        def request_body
          {
            "statements": [{"statement": query , "parameters": params}]
          }.to_json
        end

        def json
          JSON.parse response.body
        end

        def errors?
          json["errors"].length.positive?
        end

        def response
          @response ||= fetch
        end

        def fetch
          Http.new(uri).post(request_body)

        end
      end
    end
  end
end

