# frozen_string_literal: true
require_relative "call_site_query"

class A; end
class E; end

module Delfos
  module Neo4j
    describe CallSiteQuery do
      let(:container_method) do
        double "ContainerMethod",
          klass: A,                       # class A
          method_type: "ClassMethod",     #   def self.method_a    # m1
          method_name: "method_a",        #     E.new.method_e     # call site
          file: "a.rb",
          line_number: 2
      end


      let(:call_site) do
        double "CallSite",      # class A
          file: "a.rb",         #   def self.method_a    # m1
          line_number: 3,       #     E.new.method_e     # call site
          container_method: container_method,
          called_method: called_method
      end

      let(:called_method) do
        double "CalledCode",
          klass: E,                       # class E
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

        expect(params).to eq("k1" => "A",                   # class A
                             "m1_type" => "ClassMethod",    #   def self.method_a    # m1
                             "m1_name" => "method_a",       #     E.new.method_e     # call site
                             "m1_file" => "a.rb",
                             "m1_line_number" => 2,

                             "cs_file" => "a.rb",
                             "cs_line_number" => 3,

                             "k2" => "E",                   # class E
                             "m2_type" => "InstanceMethod", #   def method_e        # m2
                             "m2_name" => "method_e",       #
                             "m2_file" => "e.rb",
                             "m2_line_number" => 2)
      end

      it "#query_for" do
        query = subject.query

        expected = <<-QUERY
      MERGE (k1:Class {name: {k1}})
      MERGE (k2:Class {name: {k2}})

      MERGE (k1) - [:OWNS] ->
        (m1:Method
          {
            type: {m1_type},
            name: {m1_name},
            file: {m1_file},
            line_number: {m1_line_number}
         }
       )

      MERGE (m1) - [:CONTAINS] ->
        (cs:CallSite
          {
            file: {cs_file},
            line_number: {cs_line_number}
          }
        )

      MERGE (k2) - [:OWNS] ->
        (m2:Method
          {
            type: {m2_type},
            name: {m2_name},
            file: {m2_file},
            line_number: {m2_line_number}
         }
       )

      MERGE (cs) - [:CALLS] -> (m2)
        QUERY

        expect(strip_whitespace(query)).to eq strip_whitespace(expected)
      end
    end
  end
end
