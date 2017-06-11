module Delfos
  module Neo4j
    class QueryVariables < Hash
      def initialize
        super
        @counters = Hash.new(0)
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

    module QueryVariablesAssignment
      def assign_query_variables(*methods)
        methods.map(&:klass).uniq.each do |k|
          query_variables.assign(k, "k")
        end
      end

      def query_variable(k)
        query_variables[k.to_s]
      end

      def query_variables
        @query_variables ||= QueryVariables.new
      end
    end

  end
end
