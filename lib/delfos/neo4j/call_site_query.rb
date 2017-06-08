# frozen_string_literal: true

module Delfos
  module Neo4j
    class CallSiteQuery
      attr_reader :container_method, :call_site, :called_method

      def initialize(call_site)
        @call_site = call_site
        @container_method = call_site.container_method
        @called_method = call_site.called_method

        assign_query_variables
      end

      def params
        params = initial_params

        add_method_info(params, "m1", container_method)

        params["cs_file"]        = call_site.file
        params["cs_line_number"] = call_site.line_number

        add_method_info(params, "m2", called_method)

        params
      end

      def initial_params
        query_variables.each_with_object({}) do |(klass, name), object|
          object[name] = klass.to_s
        end
      end

      def add_method_info(params, key, code_location)
        params["#{key}_type"]        = code_location.method_type
        params["#{key}_name"]        = code_location.method_name
        params["#{key}_file"]        = code_location.file
        params["#{key}_line_number"] = code_location.line_number
      end

      def query
        klasses_query = query_variables.map do |_klass, name|
          "MERGE (#{name}:Class {name: {#{name}}})"
        end.join("\n")

        <<-QUERY
          #{klasses_query}

          MERGE (#{query_variable(container_method.klass)}) - [:OWNS] ->
            #{method_node("m1")}

          MERGE (m1) - [:CONTAINS] ->
            (cs:CallSite
              {
                file: {cs_file},
                line_number: {cs_line_number}
              }
            )

          MERGE (#{query_variable(called_method.klass)}) - [:OWNS] ->
            #{method_node("m2")}

          MERGE (cs) - [:CALLS] -> (m2)
        QUERY
      end

      def assign_query_variables
        klasses = [container_method.klass, called_method.klass]

        klasses.uniq.each do |k|
          query_variables.assign(k, "k")
        end
      end

      def method_node(id)
        <<-NODE
          (#{id}:Method
            {
              type: {#{id}_type},
              name: {#{id}_name},
              file: {#{id}_file},
              line_number: {#{id}_line_number}
            }
          )
        NODE
      end

      def query_variable(k)
        query_variables[k.to_s]
      end

      def query_variables
        @query_variables ||= QueryVariables.new
      end

      class QueryVariables < Hash
        def initialize
          super
          @counters = Hash.new(1)
        end

        def assign(klass, prefix)
          klass = klass.to_s
          val = self[klass]
          return val if val

          "#{prefix}#{@counters[prefix]}".tap do |v|
            self[klass] = v
            @counters[prefix] += 1
          end
        end
      end
    end
  end
end
