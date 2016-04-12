# frozen_string_literal: true
require "delfos"
require "neo4j/session"

module Delfos
  module Neo4j
    module QueryExecutor
      class << self
        def execute(query)
          create_session!
          ::Neo4j::Session.query(query)
        end

        def create_session!
          @create_session ||= ::Neo4j::Session.open(*Delfos.neo4j_config)
        end
      end
    end
  end
end
 
