# frozen_string_literal: true
require_relative "../distance/calculation"
require_relative "query_execution"
require "json"

module Delfos
  module Neo4j
    class DistanceUpdate
      def perform
        query = <<-QUERY
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

        results = Delfos::Neo4j::QueryExecution.execute(query)

        update(results)
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

      def update(results)
        Array(results).compact.map do |klass, call_site, call_site_id, meth, called, called_id, called_klass|
          start  = determine_full_path call_site["file"]
          finish = determine_full_path called["file"]

          calc = Delfos::Distance::Calculation.new(start, finish)

          perform_query(calc, call_site_id, called_id)
        end
      end

      def perform_query(calc, call_site_id, called_id)
        Delfos::Neo4j::QueryExecution.execute <<-QUERY
          START call_site = node(#{call_site_id}),
                called    = node(#{called_id})

           MERGE (call_site) - #{rel_for(calc)} -> (called)
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
