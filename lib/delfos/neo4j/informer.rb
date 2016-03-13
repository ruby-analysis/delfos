# frozen_string_literal: true
require "delfos"
require "neo4j"
require "neo4j/session"

module Delfos
  module Neo4j
    module Informer
      class << self
        def debug(args, caller_code, called_code)
          puts "*" * 80
          puts "
            args               #{args.args}
            keyword_args       #{args.keyword_args}

            caller_klass       #{caller_code.klass}
            caller_file        #{caller_code.file}
            caller_line_number #{caller_code.line_number}
            caller_method      #{caller_code.method_name}
            caller_method_type #{called_code.method_type}

            called_klass       #{called_code.klass}
            called_file        #{called_code.file}
            called_line_number #{called_code.line_number}
            called_method      #{called_code.method_name}
            called_method_type #{called_code.method_type}
          "

          execute_query(args, caller_code, called_code)
        end

        def query_for(_args, caller_code, called_code)
          <<-QUERY
            MERGE (k1:#{caller_code.klass})
            MERGE (k1)-[:OWNS]->(m1:#{caller_code.method_type}{name: "#{caller_code.method_name}"})
            MERGE (m1)<-[:CALLED_BY]-(mc:MethodCall{file: "#{caller_code.file}", line_number: "#{caller_code.line_number}"})

            MERGE (mc)-[:CALLS]->(m2:#{called_code.method_type}{name: "#{called_code.method_name}"})
            MERGE (k2:#{called_code.klass})
            MERGE (k2)-[:OWNS]->(m2)

            SET m2.file = "#{called_code.file}"
            SET m2.line_number = "#{called_code.line_number}"
          QUERY
        end

        def execute_query(*args)
          Delfos.check_setup!
          create_session!
          query = query_for(*args)

          ::Neo4j::Session.query(query)
        end

        private

        def create_session!
          @create_session ||= ::Neo4j::Session.open(*Delfos.neo4j_config)
        end
      end
    end
  end
end
