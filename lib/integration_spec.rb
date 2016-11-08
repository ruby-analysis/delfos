# frozen_string_literal: true
require "delfos"
require "delfos/neo4j/informer"

describe "integration" do
  before do
    Delfos.wipe_db!

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
    a_klass_count, b_klass_count, call_site_1_count, call_site_2_count,
      instance_method_1_count, instance_method_2_count, execution_count = Delfos::Neo4j::QueryExecution.execute(query).first

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

        timeout do
          load "./fixtures/sub_classes/sub_classes.rb"
        end
      end

      it do
        expect(SomeKlass).to be_a Class
        expect(SomeSubKlass).to be_a Class

        initialization = lambda do
          timeout do
            expect(SomeKlass.new).to be_a SomeSubKlass
          end
        end

        expect(initialization).not_to raise_error
      end
    end
  end
end
