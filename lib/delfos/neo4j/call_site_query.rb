# frozen_string_literal: true

module Delfos
  module Neo4j
    class CallSiteQuery
      attr_reader :args, :call_site, :called_code

      def initialize(call_site, called_code)
        @call_site = call_site
        @called_code = called_code

        assign_query_variables
      end

      def params
        params = initial_params

        add_method_info(params, "m1", call_site)

        params["cs_file"]        = call_site.file
        params["cs_line_number"] = call_site.line_number

        add_method_info(params, "m2", called_code)

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
        params["#{key}_file"]        = code_location.method_definition_file
        params["#{key}_line_number"] = code_location.method_definition_line
      end

      def query
        klasses_query = query_variables.map do |_klass, name|
          "MERGE (#{name}:Class {name: {#{name}}})"
        end.join("\n")

        <<-QUERY
          #{klasses_query}

          MERGE (#{query_variable(call_site.klass)}) - [:OWNS] ->
            #{method_node("m1")}

          MERGE (m1) - [:CONTAINS] ->
            (cs:CallSite
              {
                file: {cs_file},
                line_number: {cs_line_number}
              }
            )

          MERGE (#{query_variable(called_code.klass)}) - [:OWNS] ->
            #{method_node("m2")}

          MERGE (cs) - [:CALLS] -> (m2)
        QUERY
      end

      def assign_query_variables
        klasses = [call_site.klass, called_code.klass]

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
        def initialize(*args)
          super(*args)
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
