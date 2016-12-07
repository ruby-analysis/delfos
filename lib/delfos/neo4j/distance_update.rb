# frozen_string_literal: true
require_relative "../distance/calculation"
require_relative "query_execution"
require "json"

module Delfos
  module Neo4j
    class DistanceUpdate
      def perform
        update Delfos::Neo4j::QueryExecution.execute(query)
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

      def query
        <<-QUERY
          MATCH
            (klass)        -  [:OWNS]     -> (method),
            (method)       -  [:CONTAINS] -> (call_site),
            (call_site)    -  [:CALLS]    -> (called),
            (called_klass) -  [:OWNS]     -> (called)

          RETURN
            head(labels(klass)),
            call_site, id(call_site),
            method,
            called, id(called),
            head(labels(called_klass))
        QUERY
      end

      def update(results)
        Array(results).compact.map do |_klass, call_site, call_site_id, _meth, called, called_id, _called_klass|
          start  = determine_full_path call_site["file"]
          finish = determine_full_path called["file"]

          calc = Delfos::Distance::Calculation.new(start, finish)

          perform_query(calc, call_site_id, called_id)
        end
      end

      def perform_query(calc, call_site_id, called_id)
        Delfos::Neo4j::QueryExecution.execute <<-QUERY, {call_site_id: call_site_id, called_id: called_id, sum_traversals: calc.sum_traversals, sum_possible_traversals: calc.sum_possible_traversals}
          START call_site = node({call_site_id}),
                called    = node({called_id})

           MERGE (call_site) - #{rel} -> (called)
        QUERY
      end

      def rel
        <<-REL
           [:EFFERENT_COUPLING{
             distance:          {sum_traversals},
             possible_distance: {sum_possible_traversals}
             }
           ]
        REL
      end
    end
  end
end
