# frozen_string_literal: true
require_relative "informer"

describe Delfos::Neo4j::Informer do
  class A; end
  class B; end
  class C; end
  class D; end
  class E; end

  let(:args) { double "args", args: [B], keyword_args: [C, D] }

  before do
    Delfos.wipe_db!
  end

  let(:call_site) do
    double "CallSite",
      klass: A,
      file: "a.rb",
      line_number: 4,
      method_name: "method_a",
      method_type: "ClassMethod",
      method_definition_file: "a.rb",
      method_definition_line: 2
  end

  let(:called_code) do
    double "CalledCode",
      klass: E,
      file: "e.rb",
      line_number: 2,
      method_name: "method_e",
      method_definition_file: "some/filename",
      method_definition_line: 2,
      method_type: "InstanceMethod"
  end

  describe "#args_query" do
    before do
      subject.assign_query_variables(args, call_site, called_code)
    end

    it do
      result = subject.args_query(args)

      expect(result).to eq <<-QUERY.gsub(/^\s+/, "").chomp
        MERGE (cs) - [:ARG] -> (k3)
        MERGE (cs) - [:ARG] -> (k4)
        MERGE (cs) - [:ARG] -> (k5)
      QUERY
    end
  end

  it "#params_for" do
    params = subject.params_for(args, call_site, called_code)

    expect(params).to eq({
      "k1" => "A",
      "k2" => "E",
      "k3" => "B",
      "k4" => "C",
      "k5" => "D",
      "m1_type" => "ClassMethod",
      "m1_name" => "method_a",
      "m1_file" => "a.rb",
      "m1_line_number" => 2,

      "cs_file" => "a.rb",
      "cs_line_number" => 4,

      "m2_type" => "InstanceMethod",
      "m2_name" => "method_e",
      "m2_file" => "some/filename",
      "m2_line_number" => 2,
    })
  end

  it "#query_for" do
    query = subject.query_for(args, call_site, called_code)

    expected = <<-QUERY
      MERGE (k1:Class {name: {k1}})
      MERGE (k2:Class {name: {k2}})
      MERGE (k3:Class {name: {k3}})
      MERGE (k4:Class {name: {k4}})
      MERGE (k5:Class {name: {k5}})

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

      MERGE (cs) - [:ARG]   -> (k3)
      MERGE (cs) - [:ARG]   -> (k4)
      MERGE (cs) - [:ARG]   -> (k5)
    QUERY

    expect(strip_whitespace(query)).to eq strip_whitespace(expected)
  end

  def strip_whitespace(s)
    s.
      gsub(/^\s+/, "").
      gsub(/ +/, " ").
      gsub("\n\n", "\n")
  end
end
