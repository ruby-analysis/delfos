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
        params = {}

        QueryExecution.execute(query, params)
      end

      def query_for(args, call_site, called_code)
        assign_query_variables(args, call_site, called_code)

        klasses_query = query_variables.map do |klass, name|
          "MERGE (#{name}:Class {name: #{klass.inspect}})"
        end.join("\n")

        <<-QUERY
          #{klasses_query}

          MERGE (#{query_variable(call_site.klass)}) - [:OWNS] -> #{method_node(call_site, "m1")}

          MERGE (m1) - [:CONTAINS] -> (cs:CallSite{file: "#{call_site.file}", line_number: #{call_site.line_number}})

          MERGE (#{query_variable(called_code.klass)}) - [:OWNS] -> #{method_node(called_code, "m2")}

          MERGE (cs)  - [:CALLS]     ->  m2

          #{args_query args}
        QUERY
      end

      def assign_query_variables(args, call_site, called_code)
        klasses = [call_site.klass, called_code.klass]  + args.args + args.keyword_args

        klasses.uniq.each do |k|
          query_variables.assign(k, "k")
        end
      end

      def method_node(code, id)
        if code.method_definition_file.length.positive? && code.method_definition_line.positive?
          <<-NODE
            (#{id}:Method{type: "#{code.method_type}", name: "#{code.method_name}", file: #{code.method_definition_file.inspect}, line_number: #{code.method_definition_line}})
          NODE
        else
          <<-NODE
            (#{id}:Method{type: "#{code.method_type}", name: "#{code.method_name}"})
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
        Delfos::Patching.execution_chain
      end

      class QueryVariables < Hash
        def initialize(*args)
          super(*args)
          @counters = Hash.new(1)
        end

        def assign(klass, prefix)
          klass = klass.to_s.tr(":", "_")
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
