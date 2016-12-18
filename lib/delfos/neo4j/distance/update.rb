# frozen_string_literal: true
require "delfos/distance/calculation"

module Delfos
  module Neo4j
    module Distance
      class Update
        def perform
          update Neo4j.execute_sync(read_query)
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

        private

        def strip_block_message(f)
          f.split(" in block").first
        end

        def try_path
          path = yield
          path if path.exist?
        end

        def read_query
          <<-QUERY
          MATCH
            (call_site:CallSite) - [:CALLS] -> (called:Method)

          RETURN
            call_site.file, id(call_site),
            called.file,    id(called)
          QUERY
        end

        def update(results)
          Array(results).compact.map do |start_file, call_site_id, finish_file, called_id|
            start  = determine_full_path start_file
            finish = determine_full_path finish_file

            calc = Delfos::Distance::Calculation.new(start, finish)

            perform_query(calc.sum_traversals,
                          calc.sum_possible_traversals,
                          call_site_id,
                          called_id)
          end

          Neo4j.flush!
        end

        def perform_query(sum_traversals,
                          sum_possible_traversals,
                          call_site_id,
                          called_id)
          Neo4j.execute write_query, {
            call_site_id:            call_site_id,
            called_id:               called_id,
            sum_traversals:          sum_traversals,
            sum_possible_traversals: sum_possible_traversals
            }
        end

        def write_query
          <<-QUERY
            START call_site = node({call_site_id}),
                  called    = node({called_id})

             MERGE (call_site)
                   -
                     [:EFFERENT_COUPLING
                       {
                         distance:          {sum_traversals},
                         possible_distance: {sum_possible_traversals}
                       }
                     ]
                  -> (called)
            QUERY
        end
      end
    end
  end
end
