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
      line_number: "4",
      method_name: "method_a",
      method_type: "ClassMethod",
      method_definition_file: "a.rb",
      method_definition_line: 2
  end

  let(:called_code) do
    double "CalledCode",
      klass: E,
      file: "e.rb",
      line_number: "2",
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

  it do
    query = subject.query_for(args, call_site, called_code)

    expected = <<-QUERY
      MERGE (k1:Class {name: "A"})
      MERGE (k2:Class {name: "E"})
      MERGE (k3:Class {name: "B"})
      MERGE (k4:Class {name: "C"})
      MERGE (k5:Class {name: "D"})

      MERGE (k1) - [:OWNS] -> (m1:Method{type: "ClassMethod", name: "method_a", file: "a.rb", line_number: 2})

      MERGE (m1) - [:CONTAINS] -> (cs:CallSite{file: "a.rb", line_number: 4})

      MERGE (k2) - [:OWNS] -> (m2:Method{type: "InstanceMethod", name: "method_e", file: "some/filename", line_number: 2})
      MERGE (cs) - [:CALLS] -> m2
      MERGE (cs) - [:ARG] -> (k3)
      MERGE (cs) - [:ARG] -> (k4)
      MERGE (cs) - [:ARG] -> (k5)
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
