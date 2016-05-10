# frozen_string_literal: true
require "delfos"
require_relative "query_execution"

module Delfos
  module Neo4j
    class Informer
      def debug(args, call_site, called_code)
        execute_query(args, call_site, called_code)
      end

      def execute_query(*args)
        query = query_for(*args)

        QueryExecution.execute(query)
      end

      def query_for(args, call_site, called_code)
        assign_query_variables(args, call_site, called_code)

        klasses_query = query_variables.map do |klass, name|
          "MERGE (#{name}:#{klass})"
        end.join("\n")

        <<-QUERY
          #{klasses_query}

          #{merge_query(call_site, called_code)}
          #{args_query args}
        QUERY
      end

      def assign_query_variables(args, call_site, called_code)
        query_variables.assign(call_site.klass, "k")
        query_variables.assign(called_code.klass, "k")

        (args.args + args.keyword_args).uniq.each do |k|
          query_variables.assign(k, "k")
        end
      end

      def merge_query(call_site, called_code)
        <<-MERGE_QUERY
          #{method_definition call_site, "m1"}

          MERGE (m1) - [:CONTAINS] -> (cs:CallSite{file: "#{call_site.file}", line_number: #{call_site.line_number}})

          #{method_definition called_code, "m2"}

          MERGE (cs)  - [:CALLS]     ->  m2
        MERGE_QUERY
      end

      def method_definition(code, id)
        <<-METHOD
          MERGE (#{query_variable(code.klass)}) - [:OWNS] -> #{method_node(code, id)}
        METHOD
      end

      def method_node(code, id)
        if code.method_definition_file.length > 0 && code.method_definition_line > 0
          <<-NODE
            (#{id}:#{code.method_type}{name: "#{code.method_name}", file: #{code.method_definition_file.inspect}, line_number: #{code.method_definition_line}})
          NODE
        else
          <<-NODE
            (#{id}:#{code.method_type}{name: "#{code.method_name}"})
          NODE
        end
      end

      def args_query(args)
        (args.args + args.keyword_args).map do |k|
          name = query_variable(k)
          "MERGE (cs) - [:ARG] -> (#{name})"
        end.join("\n")
      end

      def query_variable(k)
        query_variables[k.to_s]
      end

      def query_variables
        @query_variables ||= QueryVariables.new
      end

      def code_execution_query
        Delfos::Patching.method_chain
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
