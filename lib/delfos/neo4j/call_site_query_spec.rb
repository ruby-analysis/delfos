# frozen_string_literal: true

require_relative "call_site_query"

class A; end
class E; end

module Delfos
  module Neo4j
    describe CallSiteQuery do
      let(:container_method_line_number) { 2 }
      let(:container_method_klass) { A }
      let(:called_method_klass) { E }
      let(:container_method) do
        double "ContainerMethod",
          klass: container_method_klass,  # class A
          method_type: "ClassMethod",     #   def self.method_a    # called_method
          method_name: "method_a",        #     E.new.method_e     # call site
          file: "a.rb",
          line_number: container_method_line_number
      end

      let(:call_site) do
        double "CallSite",      # class A
          file: "a.rb",         #   def self.method_a    # called_method
          line_number: 3,       #     E.new.method_e     # call site
          container_method: container_method,
          called_method: called_method
      end

      let(:called_method) do
        double "CalledCode",
          klass: called_method_klass,     # class E
          method_type: "InstanceMethod",  #   def method_e        # m2
          method_name: "method_e",        #
          file: "e.rb",
          line_number: 2
      end

      subject { described_class.new(call_site) }

      before do
        wipe_db!
      end

      it "#params" do
        params = subject.params

        expect(params).to eq("k0" => "A",                               # class A
                             "container_method_type" => "ClassMethod",  #   def self.method_a    # called_method
                             "container_method_name" => "method_a",     #     E.new.method_e     # call site
                             "container_method_file" => "a.rb",
                             "container_method_line_number" => 2,

                             "cs_file" => "a.rb",
                             "cs_line_number" => 3,

                             "k1" => "E",                              # class E
                             "called_method_type" => "InstanceMethod", #   def method_e        # m2
                             "called_method_name" => "method_e",       #
                             "called_method_file" => "e.rb",
                             "called_method_line_number" => 2)
      end

      it "#query_for" do
        query = subject.query

        expected = <<-QUERY
          MERGE (k0:Class {name: {k0}})
          MERGE (k1:Class {name: {k1}})

          MERGE (k0) - [:OWNS] ->
            (container_method:Method
              {
                type: {container_method_type},
                name: {container_method_name},
                file: {container_method_file},
                line_number: {container_method_line_number}
             }
           )

          MERGE (container_method) - [:CONTAINS] ->
            (cs:CallSite
              {
                file: {cs_file},
                line_number: {cs_line_number}
              }
            )

          MERGE (k1) - [:OWNS] ->
            (called_method:Method
              {
                type: {called_method_type},
                name: {called_method_name},
                file: {called_method_file},
                line_number: {called_method_line_number}
             }
           )

          MERGE (cs) - [:CALLS] -> (called_method)
        QUERY

        expect(strip_whitespace(query)).to eq strip_whitespace(expected)
      end

      context "with same container method and called method class" do
        let(:container_method_klass) { A }
        let(:called_method_klass) { A }

        describe "#params" do
          it "only has one class param" do
            params = subject.params

            expect(params).to eq("k0" => "A", # class A
                                 "container_method_type" => "ClassMethod",    #   def self.method_a    # container_method
                                 "container_method_name" => "method_a",       #     E.new.method_e     # call site
                                 "container_method_file" => "a.rb",
                                 "container_method_line_number" => 2,

                                 "cs_file" => "a.rb",
                                 "cs_line_number" => 3,

                                 "called_method_type" => "InstanceMethod", #   def method_e        # called_method
                                 "called_method_name" => "method_e",       #
                                 "called_method_file" => "e.rb",
                                 "called_method_line_number" => 2)
          end
        end

        describe "#query" do
          it "only creates one class node" do
            query = subject.query

            expected = <<-QUERY
              MERGE (k0:Class {name: {k0}})

              MERGE (k0) - [:OWNS] ->
                (container_method:Method
                  {
                    type: {container_method_type},
                    name: {container_method_name},
                    file: {container_method_file},
                    line_number: {container_method_line_number}
                 }
               )

              MERGE (container_method) - [:CONTAINS] ->
                (cs:CallSite
                  {
                    file: {cs_file},
                    line_number: {cs_line_number}
                  }
                )

              MERGE (k0) - [:OWNS] ->
                (called_method:Method
                  {
                    type: {called_method_type},
                    name: {called_method_name},
                    file: {called_method_file},
                    line_number: {called_method_line_number}
                 }
               )

              MERGE (cs) - [:CALLS] -> (called_method)
            QUERY

            expect(strip_whitespace(query)).to eq strip_whitespace(expected)
          end
        end
      end

      context "with missing container method line number" do
        let(:container_method_line_number) { nil }

        it do
          expect(subject.query      ).not_to include "line_number: {container_method_line_number}"
          expect(subject.params.keys).not_to include "container_method_line_number"
        end
      end
    end
  end
end
