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

        private

        def request_body
          {
            "statements": [{ "statement": strip_whitespace(query), "parameters": params }],
          }.to_json
        end

        def strip_whitespace(s)
          s.
            gsub(/^\s+/, "").
            gsub(/ +/, " ").
            gsub("\n\n", "\n")
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
          statement = strip_whitespace(query)

          if statement
            begin
            params.each { |k, v| statement = statement.gsub("{#{k}}", v.inspect) }
            rescue
            byebug
            end
            Delfos.logger.debug "sending query: "
            Delfos.logger.debug statement.gsub(/^/, "    ")
          end
        end
      end
    end
  end
end
