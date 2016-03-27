# frozen_string_literal: true
require_relative "../distance/calculation"

module Delfos
  module Neo4j
    class DistanceUpdate
      def perform
        query = <<-QUERY
          MATCH
            (klass)         -  [:OWNS]      -> (caller),
            (caller)       <-  [:CALLED_BY] -  (method_call),
            (method_call)   -  [:CALLS]     -> (called),
            (called_klass)  -  [:OWNS]      -> (called)

          RETURN klass, caller, method_call, called, called_klass
        QUERY

        result = ::Neo4j::Session.query(query)

        update(result)
      end

      def determine_full_path(f)
        f = Pathname.new f
        return f.realpath if File.exist?(f)

        Delfos.application_directories.map do |d|
          path = Pathname.new(d + f.to_s.gsub(%r{[^/]*/}, ""))
          path if path.exist?
        end.compact.first
      end

      private

      def update(result)
        result.each do |r|
          start  = determine_full_path r.caller.props[:file]
          finish = determine_full_path r.called.props[:file]

          calc = Delfos::Distance::Calculation.new(start, finish)

          perform_query(calc, r)
        end
      end

      def perform_query(calc, r)
        ::Neo4j::Session.query <<-QUERY
          START caller = node(#{r.caller.neo_id}),
                called = node(#{r.called.neo_id})

           MERGE (caller) - #{rel_for(calc)} -> (called)
        QUERY
      end

      def rel_for(calc)
        <<-REL
           [:EFFERENT_COUPLING{
             distance:          #{calc.sum_traversals},
             possible_distance: #{calc.sum_possible_traversals}
             }
           ]
        REL
      end

    end
  end
end
