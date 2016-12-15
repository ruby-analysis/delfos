module Delfos
  module Neo4j
    module QueryExecution
      class InvalidQuery  < IOError
        def initialize(errors, query, params)
          message = errors.map do |e|
            e.select{|k,_| %w(code message).include?(k) }.inspect
          end.join("\n")

          super [message, {query: query, params: params.to_json}.to_json].join("\n\n")
        end
      end

      class ConnectionError < IOError
      end
    end
  end
end
