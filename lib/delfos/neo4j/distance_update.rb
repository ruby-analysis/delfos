require_relative "../file_tree/distance_calculation"

module Delfos
  module Neo4j
    class DistanceUpdate

      def perform
        query = <<-QUERY
          MATCH (klass)-[:OWNS]->(caller),
            caller<-[:CALLED_BY]-(method_call),
            method_call-[:CALLS]->(called),
            (called_klass)-[:OWNS]->(called)

          RETURN klass, caller, method_call, called, called_klass
        QUERY

        result = ::Neo4j::Session.query(query)

        result.each do |r|
          start  = determine_full_path r.caller.props[:file]
          finish = determine_full_path r.called.props[:file]

          traversals = Delfos::FileTree::DistanceCalculation.new(start, finish).traversals
          distance = traversals.map(&:distance).inject(:+)
          possible_distance = traversals.map(&:possible_length).inject(:+)


          ::Neo4j::Session.query <<-QUERY
            START caller = node(#{r.caller.neo_id}),
                  called = node(#{r.called.neo_id})

             MERGE caller - [:EFFERENT_COUPLING{distance:#{distance}, possible_distance: #{possible_distance}}] -> called
          QUERY
        end
      end

      private

      def determine_full_path(f)
        f = Pathname.new File.expand_path f
        return f if File.exists?(f)

        Delfos.application_directories.map do |d|
          path = Pathname.new(d + f.to_s.gsub(%r{[^/]*/}, "/"))
          path if path.exist?
        end.compact.first
      end


    end
  end
end
