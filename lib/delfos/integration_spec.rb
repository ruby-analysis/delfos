# frozen_string_literal: true
describe "integration" do
  before do
    require "delfos"
    require "delfos/neo4j/informer"

    Delfos.setup!(
      application_directories: ["fixtures"],
    )

    load "fixtures/a.rb"
    load "fixtures/b.rb"
  end

  it do
    a = A.new
    b = B.new
    a.some_method(1, "", a, something: b)

    a_klass_count, b_klass_count, call_site_1_count, call_site_2_count,
      instance_method_1_count, instance_method_2_count, execution_count = Delfos::Neo4j::QueryExecution.execute(<<-QUERY).first
      MATCH (a:A)-[r:OWNS]->(im1:InstanceMethod{name: "some_method"})
      MATCH (b:B)-[r2:OWNS]->(im2:InstanceMethod{name: "another_method"})
      MATCH (im1:InstanceMethod)-[:CONTAINS]->(cs1:CallSite)-[:CALLS]->(im2:InstanceMethod)
      MATCH (im1               )-[:CONTAINS]->(cs2:CallSite)-[:CALLS]->(im2:InstanceMethod)

      MATCH cs1-[:ARG]->(a)
      MATCH cs1-[:ARG]->(b)

      MATCH cs2-[:ARG]->(b)

      MATCH (e:ExecutionChain{number: 1}) - [:STEP{number: 1}] -> (cs1)
      MATCH (e)                           - [:STEP{number: 2}] -> (cs2)

      RETURN
        count(a),   count(b),
        count(cs1), count(cs2),

        count(im1), count(im2),

        count(e)
    QUERY

    expect(a_klass_count).to eq 1
    expect(b_klass_count).to eq 1
    expect(call_site_1_count).to eq 1
    expect(call_site_2_count).to eq 1
    expect(instance_method_1_count).to eq 1
    expect(instance_method_2_count).to eq 1
    expect(execution_count).to eq 1
  end
end
