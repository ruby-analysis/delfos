# frozen_string_literal: true

require "delfos/file_system"
require_relative "call_site_fetcher"

module Delfos
  module Neo4j
    module Distance
      class Update
        def perform
          results = CallSiteFetcher.perform
          return unless results.length.positive?

          results.each do |start_file, call_site_id, finish_file, called_id|
            handle(start_file, call_site_id, finish_file, called_id)
          end

          Neo4j.flush!
        end

        def update(call_site_id, called_id, calc)
          Neo4j.execute(
            query,
            call_site_id:            call_site_id,
            called_id:               called_id,
            sum_traversals:          calc.sum_traversals,
            sum_possible_traversals: calc.sum_possible_traversals,
          )
        end

        def query
          <<-QUERY
            START call_site = node({call_site_id}),
                  called    = node({called_id})

             MERGE (call_site)
               -
                 [:EFFERENT_COUPLING {
                     distance:          {sum_traversals},
                     possible_distance: {sum_possible_traversals}
                   }
                 ]
               -> (called)
          QUERY
        end

        private

        def handle(start_file, call_site_id, finish_file, called_id)
          calc = FileSystem.distance_calculation(start_file, finish_file)

          update(call_site_id, called_id, calc)
        rescue FileSystem::Error => e
          error(e, start_file, call_site_id, finish_file, called_id)
        end

        def error(err, start_file, call_site_id, finish_file, called_id)
          Delfos.logger.error([
            "Whilst updating distance #{start_file}->#{finish_file} ",
            "call_site_id: #{call_site_id}",
            "called_id: #{called_id} - #{err.message} #{err.backtrace}",
          ].join("\n"))
        end
      end
    end
  end
end
