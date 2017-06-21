# frozen_string_literal: true

require_relative "query_variables"

module Delfos
  module Neo4j
    class CallSiteQuery
      include QueryVariablesAssignment

      attr_reader :container_method, :call_site, :called_method, :stack_uuid, :step_number

      def initialize(call_site, stack_uuid, step_number)
        @call_site        = call_site
        @container_method = call_site.container_method
        @called_method    = call_site.called_method
        @stack_uuid       = stack_uuid
        @step_number      = step_number

        assign_query_variables(container_method, called_method)
      end

      def params
        params = calculate_params

        if container_method.line_number.nil?
          params.delete "container_method_line_number"
        end

        params
      end

      def klass_params
        query_variables.each_with_object({}) do |(klass, name), object|
          object[name] = klass.to_s
        end
      end

      def add_method_info(params, key, meth)
        params["#{key}_type"]        = meth.method_type
        params["#{key}_name"]        = meth.method_name
        params["#{key}_file"]        = meth.file
        params["#{key}_line_number"] = meth.line_number
      end

      def query
        klasses_query = query_variables.values.map do |name|
          "MERGE (#{name}:Class {name: {#{name}}})"
        end.join("\n")

        <<-QUERY
          #{klasses_query}

          MERGE (#{query_variable(container_method.klass)}) - [:OWNS] ->
            #{method_node("container_method", include_line_number: include_container_method_line_number?)}

          MERGE (container_method) - [:CONTAINS] ->
            (call_site:CallSite
              {
                file: {call_site_file},
                line_number: {call_site_line_number}
              }
            )

          MERGE (#{query_variable(called_method.klass)}) - [:OWNS] ->
            #{method_node("called_method")}

          MERGE (call_site) - [:CALLS] -> (called_method)

          #{call_stack_query}
        QUERY
      end

      def call_stack_query
        <<-QUERY
          MERGE (call_stack:CallStack{uuid: {stack_uuid}})

          MERGE (call_stack) - [:STEP {number: {step_number}}] -> (call_site)
        QUERY
      end

      def method_node(id, include_line_number: true)
        <<-NODE
          (#{id}:Method
            {
              type: {#{id}_type},
              name: {#{id}_name},
              file: {#{id}_file}#{"," if include_line_number}
              #{"line_number: {#{id}_line_number}" if include_line_number}
            }
          )
        NODE
      end

      private

      def include_container_method_line_number?
        params.keys.include?("container_method_line_number")
      end

      def calculate_params
        params = klass_params
        params["step_number"] = step_number
        params["stack_uuid"] = stack_uuid

        add_method_info(params, "container_method", container_method)

        params["call_site_file"]        = call_site.file
        params["call_site_line_number"] = call_site.line_number

        add_method_info(params, "called_method", called_method)

        params
      end
    end
  end
end
