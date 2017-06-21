# frozen_string_literal: true

require_relative "call_site_query"

class A; end
class E; end

module Delfos
  module Neo4j
    describe CallSiteQuery do
      let(:step_number) { 0 }
      let(:stack_uuid) { "some-uuid" }
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

      subject { described_class.new(call_site, stack_uuid, step_number) }

      before do
        wipe_db!
      end

      it "#params" do
        params = subject.params

        expect(params).to eq("container_method_klass_name" => "A",           # class A
                             "container_method_type" => "ClassMethod",  #   def self.method_a    # called_method
                             "container_method_name" => "method_a",     #     E.new.method_e     # call site
                             "container_method_file" => "a.rb",
                             "container_method_line_number" => 2,

                             "call_site_file"        => "a.rb",
                             "call_site_line_number" => 3,
                             "stack_uuid" => stack_uuid,
                             "step_number" => step_number,

                             "called_method_klass_name" => "E",                              # class E
                             "called_method_type" => "InstanceMethod", #   def method_e        # m2
                             "called_method_name" => "method_e",       #
                             "called_method_file" => "e.rb",
                             "called_method_line_number" => 2)
      end

      it "#query_for" do
        query = subject.query

        expected = <<-QUERY
          MERGE (container_method_klass:Class {name: {container_method_klass_name}})
          MERGE (called_method_klass:Class {name: {called_method_klass_name}})

          MERGE (container_method_klass) - [:OWNS] ->
            (container_method:Method
              {
                type: {container_method_type},
                name: {container_method_name},
                file: {container_method_file},
                line_number: {container_method_line_number}
             }
           )

          MERGE (container_method) - [:CONTAINS] ->
            (call_site:CallSite
              {
                file: {call_site_file},
                line_number: {call_site_line_number}
              }
            )

          MERGE (called_method_klass) - [:OWNS] ->
            (called_method:Method
              {
                type: {called_method_type},
                name: {called_method_name},
                file: {called_method_file},
                line_number: {called_method_line_number}
             }
           )

          MERGE (call_site) - [:CALLS] -> (called_method)
          MERGE (call_stack:CallStack{uuid: {stack_uuid}})
          MERGE (call_stack) - [:STEP {number: {step_number}}] -> (call_site)

        QUERY

        expect(strip_whitespace(query)).to eq strip_whitespace(expected)
      end

      context "with same container method and called method class" do
        let(:container_method_klass) { A }
        let(:called_method_klass) { A }

        describe "#params" do
          it "only has one class param" do
            params = subject.params

            expect(params).to eq("container_method_klass_name" => "A",        # class A
                                 "container_method_type" => "ClassMethod",    #   def self.method_a    # container_method
                                 "container_method_name" => "method_a",       #     E.new.method_e     # call site
                                 "container_method_file" => "a.rb",
                                 "container_method_line_number" => 2,

                                 "call_site_file" => "a.rb",
                                 "call_site_line_number" => 3,
                                 "stack_uuid" => stack_uuid,
                                 "step_number" => step_number,

                                 "called_method_klass_name" => "A",        #   def method_e        # called_method
                                 "called_method_type" => "InstanceMethod", #   def method_e        # called_method
                                 "called_method_name" => "method_e",       #
                                 "called_method_file" => "e.rb",
                                 "called_method_line_number" => 2)
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
