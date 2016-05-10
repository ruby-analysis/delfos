require_relative "query_execution"

module Delfos
  module Neo4j
    class ExecutionPersistence
      def self.save!(other)
        new(other.call_sites, other.execution_count).save!
      end

      def save!
        Neo4j::QueryExecution.execute query
      end

      private

      def initialize(call_sites, execution_count)
        @call_sites = call_sites

        @execution_count = execution_count
      end

      attr_reader :call_sites, :execution_count

      def query
        call_sites.compact.map.with_index do |c, i|
          call_site_query(c, i)
        end.join("\n")
      end

      def call_site_query(cs, i)
        <<-QUERY
        #{method_query(cs, i)}

      MERGE
        (m#{i})

        -[:CONTAINS]->

        (cs#{i}:CallSite {file: "#{cs.file}", line_number: #{cs.line_number}})

        #{execution_chain_query(cs, i)}
        QUERY
      end

      def execution_chain_query(cs, i)
        <<-QUERY
        MERGE (e#{i}:ExecutionChain{number: #{execution_count}})

        MERGE e#{i}-[:STEP{number: #{i + 1}}]-> (cs#{i})
        QUERY
      end

      def method_query(cs, i)
        <<-QUERY
        MERGE (k#{i}:#{cs.klass})
        - [:OWNS] ->

        (m#{i} :#{cs.method_type} {name: "#{cs.method_name}", file: "#{cs.method_definition_file}", line_number: #{cs.method_definition_line}})
        QUERY
      end
    end
  end
end
