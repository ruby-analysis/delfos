# frozen_string_literal: true
require "delfos"
require "neo4j"
require "neo4j/session"

module Delfos
  module Neo4j
    class Informer
      def debug(args, caller_code, called_code)
        execute_query(args, caller_code, called_code)
      end

      def execute_query(*args)
        Delfos.check_setup!
        self.class.create_session!
        query = query_for(*args)

        ::Neo4j::Session.query(query)
      end

      def query_for(args, caller_code, called_code)
        assign_query_variables(args, caller_code, called_code)

        klasses_query = query_variables.map do |klass, name|
          "MERGE (#{name}:#{klass})"
        end.join("\n")

        <<-QUERY
          #{klasses_query}

          #{merge_query(caller_code, called_code)}
          #{args_query args}

          #{set_query(caller_code, called_code)}
        QUERY
      end

      def assign_query_variables(args, caller_code, called_code)
        query_variables.assign(caller_code.klass, "k")
        query_variables.assign(called_code.klass, "k")

        (args.args + args.keyword_args).uniq.each do |k|
          query_variables.assign(k, "k")
        end
      end

      def merge_query(caller_code, called_code)
        <<-MERGE_QUERY
          MERGE (#{query_variable(caller_code.klass)}) - [:OWNS]      ->  (m1:#{caller_code.method_type}{name: "#{caller_code.method_name}"})

          MERGE (m1) <- [:CALLED_BY] -  (mc:MethodCall{file: "#{caller_code.file}", line_number: "#{caller_code.line_number}"})

          MERGE (mc)  - [:CALLS]     -> (m2:#{called_code.method_type}{name: "#{called_code.method_name}"})
          MERGE (#{query_variable(called_code.klass)})-[:OWNS]->(m2)
        MERGE_QUERY
      end

      def set_query(caller_code, called_code)
        <<-QUERY
          SET m1.file = "#{caller_code.method_definition_file}"
          SET m1.line_number = "#{caller_code.method_definition_line}"

          SET m2.file = "#{called_code.file}"
          SET m2.line_number = "#{called_code.line_number}"
        QUERY
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

      def args_query(args)
        (args.args + args.keyword_args).map do |k|
          name = query_variable(k)
          "MERGE (mc) - [:ARG] -> (#{name})"
        end.join("\n")
      end

      def self.create_session!
        @create_session ||= ::Neo4j::Session.open(*Delfos.neo4j_config)
      end
    end
  end
end
