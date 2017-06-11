# frozen_string_literal: true
require_relative "query_variables"

module Delfos
  module Neo4j
    class CallStackQuery
      include QueryVariablesAssignment

      def initialize(call_sites, execution_count)
        @call_sites = call_sites

        @execution_count = execution_count

        call_sites.each do |cs|
          assign_query_variables(cs.container_method)
        end
      end

      def query
        map_call_sites do |c, i|
          call_site_query(c, i)
        end.join("\n")
      end

      def params
        params = {}

        map_call_sites do |c, i|
          params.merge!(call_site_params(c, i))
          params.merge!(container_method_params(c.container_method, i))
        end

        params
      end

      private

      attr_reader :call_sites, :execution_count

      def map_call_sites(&block)
        call_sites.map.with_index(&block)
      end

      def klasses_query
        query_variables.values.map do |v|
          "MERGE ( #{v}:Class { name: {klass#{v.gsub("k", "")}} })"
        end.join("\n")
      end

      def call_site_query(cs, i)
        container_klass_key = query_variable(cs.container_method.klass)

        <<-QUERY
          #{klasses_query if i.zero?}

          MERGE

          (
            #{container_klass_key}
          )

          - [:OWNS] ->

          (
            m#{i} :Method {
              type: {method_type#{i}},
              name: {method_name#{i}},
              file: {file#{i}},
              line_number: {method_definition_line#{i}}}
          )

          MERGE

          (m#{i})

          -[:CONTAINS]->

          (cs#{i}:CallSite {file: {file#{i}}, line_number: {line_number#{i}}})

          #{i == 0 ? "CREATE (e:CallStack)" : ""}

          MERGE (e)
            -
            [:STEP {number: {step_number#{i}}}]
            ->
          (cs#{i})
        QUERY
      end

      def container_method_params(m, i)
        k = query_variable(m.klass).gsub(/k/, "")

        {
          "klass#{k}"                  => m.klass.to_s,
          "method_name#{i}"            => m.method_name,
          "method_type#{i}"            => m.method_type,
          "method_definition_line#{i}" => m.line_number,
        }
      end

      def call_site_params(cs, i)
        {
          "file#{i}"                   => cs.file,
          "line_number#{i}"            => cs.line_number,
          "execution_count#{i}"        => execution_count,
          "step_number#{i}"            => i + 1,
        }
      end
    end
  end
end
