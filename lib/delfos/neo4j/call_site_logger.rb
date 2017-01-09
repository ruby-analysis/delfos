# frozen_string_literal: true

module Delfos
  module Neo4j
    class CallSiteLogger
      def save_call_stack(call_sites, execution_number)
        q = Neo4j::CallStackQuery.new(call_sites, execution_number)
        Neo4j.execute(q.query, q.params)
      end

      def log(args, call_site, called_code)
        builder = QueryBuilder.new(args, call_site, called_code)

        Neo4j.execute(builder.query, builder.params)
      end
    end

    class QueryBuilder
      attr_reader :args, :call_site, :called_code

      def initialize(args, call_site, called_code)
        @args = args
        @call_site = call_site
        @called_code = called_code

        assign_query_variables
      end

      def params
        params = query_variables.each_with_object({}) do |(klass, name), object|
          object[name] = klass.to_s
        end

        params["m1_type"]        = call_site.method_type
        params["m1_name"]        = call_site.method_name
        params["m1_file"]        = call_site.method_definition_file
        params["m1_line_number"] = call_site.method_definition_line

        params["cs_file"]        = call_site.file
        params["cs_line_number"] = call_site.line_number

        params["m2_type"]        = called_code.method_type
        params["m2_name"]        = called_code.method_name
        params["m2_file"]        = called_code.method_definition_file
        params["m2_line_number"] = called_code.method_definition_line

        params
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

          #{args_query}
        QUERY
      end

      def assign_query_variables
        klasses = [call_site.klass, called_code.klass] + args.argument_classes

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

      def args_query
        query_text = args.argument_classes.map do |k|
          name = query_variable(k)
          "MERGE (cs) - [:ARG] -> (#{name})"
        end

        query_text.join("\n")
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
