# frozen_string_literal: true
require "delfos"
require "json"

module Delfos
  module Neo4j
    module QueryExecution
      class << self
        def execute(query, url=nil)
          result = JSON.parse response_for(query)
          result["results"].first["data"].map{|r| r["row"]}
        end

        private

        def response_for(query)
          body = <<-BODY.gsub(/^\s+/, "").chomp
            {"statements": [ { "statement": #{query.inspect} }]}
          BODY
          url = "http://neo4j:password@localhost:7474/db/data/transaction/commit"

          command = "curl  #{headers} --data-ascii '#{body}' #{url} 2> /dev/null"

          `#{command}`
        end

        def headers
          <<-HEADERS.chomp
            -H "User-Agent: delfos" -H "Accept: application/json; charset=UTF-8" -H "Content-Type: application/json" 
          HEADERS
        end
      end
    end
  end
end



