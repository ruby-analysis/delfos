# frozen_string_literal: true
require_relative "informer"

describe Delfos::Neo4j::Informer do
  class A; end
  class B; end
  class C; end
  class D; end
  class E; end

  let(:args) { double args: [B], keyword_args: [C,D] }

  let(:caller_code) {
    double klass: A,

    file: "a.rb",
    line_number: "4",
    method_name: "method_a",
    method_type: "ClassMethod",
    method_definition_file: "a.rb",
    method_definition_line: 2
  }

  let(:called_code) {
    double klass: E,
    file: "e.rb",
    line_number: "2",
    method_name: "method_e",
    method_type: "InstanceMethod"
  }

  describe "#args_query" do
    it do
      result = described_class.args_query(args)
      expect(result).to eq <<-QUERY.gsub(/^\s+/, "").chomp
        MERGE (mc) - [:ARG] -> (k2)
        MERGE (mc) - [:ARG] -> (k4)
        MERGE (mc) - [:ARG] -> (k5)
      QUERY
    end
  end

  it do
    query = described_class.query_for(args, caller_code, called_code)

    expected = <<-QUERY
      MERGE (k1:A)
      MERGE (k2:B)
      MERGE (k3:E)
      MERGE (k4:C)
      MERGE (k5:D)

      MERGE (k1)  - [:OWNS]      -> (m1:ClassMethod{name: "method_a"})
      MERGE (m1) <- [:CALLED_BY] -  (mc:MethodCall{file: "a.rb", line_number: "4"})
      MERGE (mc)  - [:CALLS]     -> (m2:InstanceMethod{name: "method_e"})

      MERGE (k3)-[:OWNS]->(m2)

      MERGE (mc) - [:ARG] -> (k2)
      MERGE (mc) - [:ARG] -> (k4)
      MERGE (mc) - [:ARG] -> (k5)

      SET m1.file = "a.rb"
      SET m1.line_number = "2"
      SET m2.file = "e.rb"
      SET m2.line_number = "2"
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
