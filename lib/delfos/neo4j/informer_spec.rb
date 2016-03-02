require_relative "informer"

describe Delfos::Neo4j::Informer do
  it "with zero args" do
    class_method        = false
    args                = double args: [], keyword_args: []

    caller_code = double klass: "A", file: "a.rb", line_number: "4", method_name: "method_a", method_type: "ClassMethod"
    called_code = double klass: "B", file: "b.rb", line_number: "2", method_name: "method_b", method_type: "InstanceMethod"

    query = described_class.query_for(args, caller_code, called_code)

    expected = <<-QUERY
      MERGE (k1:A)
      MERGE (k1)-[:OWNS]->(m1:ClassMethod{name: "method_a"})
      MERGE (m1)<-[:CALLED_BY]-(mc:MethodCall{file: "a.rb", line_number: "4"})

      MERGE (mc)-[:CALLS]->(m2:InstanceMethod{name: "method_b"})
      MERGE (k2:B)
      MERGE (k2)-[:OWNS]->(m2)

      SET m2.file = "b.rb"
      SET m2.line_number = "2"
    QUERY

    expect(strip_whitespace query).to eq strip_whitespace(expected)
  end

  def strip_whitespace(s)
    s.
      gsub(/^\s*/, "").
      gsub("  ", " ").
      gsub("\n\n", "\n")
  end
end
