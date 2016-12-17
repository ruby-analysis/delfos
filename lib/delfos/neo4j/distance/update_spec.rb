# frozen_string_literal: true
require_relative "update"
require "delfos"

module Delfos
  module Neo4j
    module Distance
      describe Update do
        def preload_graph!
          wipe_db!
          Delfos.reset!
          Delfos.setup_neo4j!
          perform_query File.read "fixtures/cypher/coupling.cypher"
        end

        before(:all) do
          preload_graph!

          described_class.new.perform

          query = <<-QUERY
            MATCH
              (klass)        - [:OWNS]              -> (method),
              (method )      - [:CONTAINS]          -  (call_site),
              (call_site)    - [:CALLS]             -> (called),
              (called_klass) - [:OWNS]              -> (called),
              (call_site)    - [:EFFERENT_COUPLING] -> (called)

            RETURN

              klass.name,
              method,
              call_site, id(call_site),
              called, id(called),
              called_klass.name
          QUERY

          @result = Delfos::Neo4j.execute_sync(query)
        end

        MAPPING = { klass: 0, method: 1, call_site: 2, called: 4, called_klass: 6 }.freeze

        def parse_result(key)
          @result.map { |r| r[MAPPING[key]] }.flatten.uniq
        end

        it "records the Classes" do
          klasses = parse_result(:klass)

          expect(klasses.flatten.uniq).to eq ["EfferentCoupling"]
        end

        it "records the called classes" do
          called_klasses = parse_result(:called_klass)
          expect(called_klasses).to match_array %w(This That SomeOther SoMuchCoupling HereIsSomeMore)
        end

        describe "call_site" do
          it "returns the call_site" do
            expect(parse_result(:call_site).length).to eq 7
          end

          it "records the call_site details" do
            files = parse_result(:call_site).map{|r| r["file"]}.uniq
            lines = parse_result(:call_site).map{|r| r["line_number"]}.sort
            expect(files).to eq ["fixtures/ruby/efferent_coupling.rb"]
            expect(lines).to eq [6,7,8,9,10,11,12]
          end
        end

        it "records the called method details" do
          file_path = "fixtures/ruby/this.rb"

          calleds = parse_result(:called)

          expect(calleds).to match_array [
            { "file" => file_path, "name" => "send_message",     "line_number" => 3,  "type"=>"ClassMethod" },
            { "file" => file_path, "name" => "found_in_here",    "line_number" => 13, "type"=>"ClassMethod" },
            { "file" => file_path, "name" => "for_good_measure", "line_number" => 17, "type"=>"ClassMethod" },
          ]
        end

        describe "#determine_full_path" do
          before do
            Delfos.setup! application_directories: ["fixtures/ruby"]
          end

          it do
            result = subject.determine_full_path("/ruby/this.rb")

            expect(result.to_s).to eq File.expand_path("fixtures/ruby/this.rb").to_s
          end
        end
      end
    end
  end
end
