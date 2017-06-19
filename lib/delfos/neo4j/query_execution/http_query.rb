# frozen_string_literal: true

module Delfos
  module Neo4j
    module QueryExecution
      module HttpQuery
        def self.included(base)
          base.instance_eval do
            attr_reader :query, :params
          end
        end

        def initialize(query, params, uri = nil)
          @query = query
          @params = params
          @uri = uri
        end

        def query_length
          request_body.length
        end

        private

        def request_body
          @request_body ||= {
            "statements": [{ "statement": formatted_query, "parameters": params }],
          }.to_json
        end

        def formatted_query
          strip_whitespace(query)
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
          log_query

          Http.new(uri).post(request_body)
        end

        def log_query
          Delfos.logger.debug do
            statement = formatted_query

            params.each { |k, v| statement = statement.gsub("{#{k}}", v.inspect) }
            statement.gsub(/^/, "    ")
          end
        end

        def strip_whitespace(s)
          s.
            gsub(/^\s+/, "").
            gsub(/ +/, " ").
            gsub("\n\n", "\n")
        end
      end
    end
  end
end
