# frozen_string_literal: true
module Delfos
  module Neo4j
    module Schema
      extend self

      def ensure_constraints!(required)
        log "checking constraints"

        if satisfies_constraints?(required)
          log "Neo4j schema constraints satisfied"
        else
          warn "Neo4j schema constraints not satisfied - adding"

          required.each do |label, attribute|
            create_constraint(label, attribute)
          end

          log "Constraints added"
        end
      end

      def decorate(msg)
        line = "-" * 80

        <<-MSG
          #{line}
          #{msg}
          #{line}
        MSG
      end

      private

      def warn(s)
        log(s, :warn)
      end

      def log(s, type = :debug)
        Delfos.logger.send(type, decorate(s))
      end

      def create_constraint(label, attribute)
        Neo4j.execute_sync <<-QUERY
          CREATE CONSTRAINT ON (c:#{label}) ASSERT c.#{attribute} IS UNIQUE
        QUERY
      end

      def satisfies_constraints?(required)
        existing_constraints = fetch_existing_constraints

        required.inject(true) do |_result, (label, attribute)|
          constraint = existing_constraints.find { |c| c["label"] == label }

          constraint && constraint["property_keys"].include?(attribute)
        end
      end

      def fetch_existing_constraints
        response = QueryExecution::Http.new(constraints_uri).get

        if response.code == "200"
          JSON.parse response.body
        else
          raise IOError.new uri, response
        end
      end

      private

      def constraints_uri
        Delfos.neo4j.uri_for("/db/data/schema/constraint")
      end
    end
  end
end
