# frozen_string_literal: true

require_relative "importer"

module Delfos
  module Neo4j
    module Offline
      RSpec.describe Importer do
        describe ".perform" do
          let(:part_query) do
            "MERGE (container_method_klass:Class {name: {container_method_klass_name}})
             MERGE (called_method_klass:Class {name: {called_method_klass_name}})
             MERGE (container_method_klass) - [:OWNS] ->"
          end
          let(:queries) { "fixtures/offline/import.cypher" }
          subject { described_class.new(queries) }

          # rubocop:disable Metrics/BlockLength
          it "executes the queries in the file" do
            count = 0

            expect(Delfos::Neo4j).to receive(:execute_sync) do |query, params|
              count += 1
              case count
              when 1
                expect(strip_whitespace(query)).to include strip_whitespace(part_query)
                expect(params).to match(
                  "call_site_file"               => "fixtures/a_usage.rb",
                  "call_site_line_number"        => 3,
                  "called_method_file"           => "fixtures/a.rb",
                  "called_method_line_number"    => 5,
                  "called_method_name"           => "some_method",
                  "called_method_type"           => "InstanceMethod",
                  "container_method_file"        => "fixtures/a_usage.rb",
                  "container_method_line_number" => 3,
                  "container_method_name"        => "(main)",
                  "container_method_type"        => "InstanceMethod",
                  "container_method_klass_name"  => "Object",
                  "called_method_klass_name"     => "A",
                  "stack_uuid"                   => "e0b5221b-acda-44be-a75c-98590e963344",
                  "step_number"                  => 1,
                )
              when 11
                expect(params).to match(
                  "call_site_file"               => "fixtures/a.rb",
                  "call_site_line_number"        => 8,
                  "called_method_file"           => "fixtures/a.rb",
                  "called_method_line_number"    => 21,
                  "called_method_name"           => "some_class_method",
                  "called_method_type"           => "ClassMethod",
                  "container_method_file"        => "fixtures/a.rb",
                  "container_method_line_number" => 5,
                  "container_method_name"        => "some_method",
                  "container_method_type"        => "InstanceMethod",
                  "container_method_klass_name"  => "A",
                  "called_method_klass_name"     => "D",
                  "stack_uuid"                   => "e0b5221b-acda-44be-a75c-98590e963344",
                  "step_number"                  => 11,
                )
              end
            end.exactly(11).times

            subject.perform
          end
        end
      end
    end
  end
end
