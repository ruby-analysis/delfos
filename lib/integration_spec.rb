# frozen_string_literal: true
require "delfos"
require "delfos/neo4j"

describe "integration" do
  before do
    wipe_db!

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

    query = <<-QUERY
      MATCH (a:Class{name: "A"})  -  [:OWNS]  -> (ma:Method{type: "InstanceMethod", name: "some_method"})

      MATCH (b:Class{name: "B"})  -  [:OWNS] ->  (mb:Method{type: "InstanceMethod", name: "another_method"})

      MATCH (c:Class{name: "C"})  -  [:OWNS] ->  (mc:Method{type: "InstanceMethod", name: "method_with_no_more_method_calls"})

      MATCH (ma)-[:CONTAINS]->(csA2B:CallSite)-[:CALLS]->(mb)
      MATCH (mb)-[:CONTAINS]->(csB2C:CallSite)-[:CALLS]->(mc)

      MATCH (ma)-[:CONTAINS]->(csA2C:CallSite)-[:CALLS]->(mc)

      MATCH (csA2B)-[:ARG]->(a)

      MATCH (e:CallStack) - [:STEP{number: 1}] -> (csA2B)
      MATCH (e) - [:STEP{number: 2}] -> (csB2A:CallSite)

      MATCH (e2:CallStack)  - [:STEP{number: 1}] -> (csA2C)


      RETURN
        count(a),
        count(b),
        count(csA2B),
        count(csB2C),
        count(csA2C),
        count(mb),
        count(e)


    QUERY

    Delfos::Neo4j.flush!

    a_klass_count, b_klass_count, call_site_1_count, call_site_2_count,
      instance_method_1_count, instance_method_2_count, execution_count =
      Delfos::Neo4j.execute_sync(query).first

    expect(b_klass_count).to eq 1
    expect(a_klass_count).to eq 1
    expect(call_site_1_count).to eq 1
    expect(call_site_2_count).to eq 1
    expect(instance_method_1_count).to eq 1
    expect(instance_method_2_count).to eq 1
    expect(execution_count).to eq 1
  end

  context "with a call to super inside new" do
    before do
      Object.send(:remove_const, :SomeKlass) if defined? ::SomeKlass
      Object.send(:remove_const, :SomeSubKlass) if defined? ::SomeSubKlass
    end

    context "without Delfos enabled" do
      before do
        load "./fixtures/sub_classes/sub_classes.rb"
      end

      it do
        expect(SomeKlass).to be_a Class
        expect(SomeSubKlass).to be_a Class

        expect(SomeKlass.new).to be_a SomeSubKlass
      end
    end

    context "with Delfos enabled" do
      before do
        Delfos.setup! application_directories: ["./fixtures/sub_classes"]

        load "./fixtures/sub_classes/sub_classes.rb"
      end

      it do
        expect(SomeKlass).to be_a Class
        expect(SomeSubKlass).to be_a Class

        initialization = lambda do
          expect(SomeKlass.new).to be_a SomeSubKlass
        end

        expect(initialization).not_to raise_error
      end
    end
  end
end
