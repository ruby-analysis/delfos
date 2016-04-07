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

    result = Neo4j::Session.query <<-QUERY
      MATCH (a:A)-[r:OWNS]->(im1:InstanceMethod{name: "some_method"})
      MATCH (b:B)-[r2:OWNS]->(im2:InstanceMethod{name: "another_method"})
      MATCH (im1:InstanceMethod)-[:CONTAINS]->(cs:CallSite)-[:CALLS]->(im2:InstanceMethod)

      MATCH cs-[:ARG]->(a)
      MATCH cs-[:ARG]->(b)

      MATCH (e:Execution) - [:STEP{number: 1}] -> (im1)
      MATCH (e)           - [:STEP{number: 2}] -> (cs)
      MATCH (e)           - [:STEP{number: 3}] -> (im2)

      RETURN count(a),count(b),count(cs),count(e),count(im1),count(im2)
    QUERY

    expect(result.first["count(a)"]).to eq 1
    expect(result.first["count(b)"]).to eq 1
    expect(result.first["count(im1)"]).to eq 1
    expect(result.first["count(cs)"]).to eq 1
    expect(result.first["count(im2)"]).to eq 1
    expect(result.first["count(e)"]).to eq 1
  end
end
