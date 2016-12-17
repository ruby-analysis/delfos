# frozen_string_literal: true
require "delfos/distance/calculation"

module Delfos
  module Neo4j
    module Distance
      class Update
        def perform
          update read_query
        end

        def determine_full_path(f)
          f = strip_block_message(f)
          f = Pathname.new f
          return f.realpath if File.exist?(f)

          Delfos.application_directories.map do |d|
            path = try_path{ d + f }

            path || try_path do
              Pathname.new(d + f.to_s.gsub(%r{[^/]*/}, ""))
            end
          end.compact.first
        end

        def read_query
          Neo4j.execute_sync(query)
        end

        private

        def strip_block_message(f)
          f.split(" in block").first
        end

        def try_path
          path = yield
          path if path.exist?
        end

        def query
          <<-QUERY
          MATCH
            (:Class)             -  [:OWNS]     -> (method:Method)
                                 -  [:CONTAINS] -> (call_site:CallSite)
                                 -  [:CALLS]    -> (called:Method)
                                <-  [:OWNS]     -  (:Class)

          RETURN
            call_site, id(call_site),
            called,    id(called)
          QUERY
        end

        def update(results)
          Array(results).compact.map do |call_site, call_site_id, called, called_id|
            start  = determine_full_path call_site["file"]
            finish = determine_full_path called["file"]

            calc = Delfos::Distance::Calculation.new(start, finish)

            perform_query(calc, call_site_id, called_id)
          end

          Neo4j.flush!
        end

        def perform_query(calc, call_site_id, called_id)
          Neo4j.execute <<-QUERY, {call_site_id: call_site_id, called_id: called_id, sum_traversals: calc.sum_traversals, sum_possible_traversals: calc.sum_possible_traversals}
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
end
