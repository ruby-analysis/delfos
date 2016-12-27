# frozen_string_literal: true
require "delfos"
require "delfos/neo4j"

describe "integration" do
  let(:result) do
    Delfos::Neo4j.flush!
    Delfos::Neo4j.execute_sync(query).first
  end

  before(:each) do
    wipe_db!

    Delfos.setup!(
      application_directories: ["fixtures"],
    )

    load "fixtures/a.rb"
    load "fixtures/b.rb"

    a = A.new
    b = B.new
    a.some_method(1, "", a, something: b)
    Delfos::Neo4j.flush!
  end

  after do
    Delfos.reset!
  end

  context "recording call stacks" do
    let(:query) do
      <<-QUERY
       MATCH (e:CallStack) - [:STEP{number: 1}] -> (:CallSite) -[:CALLS]->(:Method)<-[:OWNS]-(:Class{name:"B"})
       MATCH (e)           - [:STEP{number: 2}] -> (:CallSite) -[:CALLS]->(:Method)<-[:OWNS]-(:Class{name:"A"})
       MATCH (e2:CallStack)- [:STEP{number: 1}] -> (:CallSite) -[:CALLS]->(:Method)<-[:OWNS]-(:Class{name:"C"})
       RETURN count(e), count(e2)
      QUERY
    end

    it do
      e_count, e2_count = result

      expect(e_count).to eq 1
      expect(e2_count).to eq 1
    end
  end

  context "records arguments" do
    let(:query) do
      <<-QUERY
        MATCH (:CallSite)-[arg:ARG]->(a:Class{name: "A"})

        RETURN count(arg)
      QUERY
    end

    it do
      arg_count = result.first

      expect(arg_count).to eq 1
    end
  end

  context "records call sites" do
    let(:query) do
      <<-QUERY
      MATCH (b:Class{name: "B"})  -  [:OWNS]
        ->  (mb:Method{type: "InstanceMethod", name: "another_method"})
        -[:CONTAINS]->(csB2C:CallSite)-[:CALLS]->(mc)

      MATCH (a:Class{name: "A"})  -  [:OWNS]
        -> (ma:Method{name: "some_method"}) -[:CONTAINS]
        ->(csA2B:CallSite)-[:CALLS]
        ->(mb)

      MATCH (ma)-[:CONTAINS]
        ->(csA2C:CallSite)
        -[:CALLS]
        -> (mc:Method{type: "InstanceMethod", name: "method_with_no_more_method_calls"})
        <- [:OWNS] - (c:Class{name: "C"})

      RETURN
        count(csA2B),
        count(csB2C),
        count(csA2C)
      QUERY
    end

    it do
      call_site_1_count, call_site_2_count, call_site_3_count =
        result

      expect(call_site_1_count).to eq 1
      expect(call_site_2_count).to eq 1
      expect(call_site_3_count).to eq 1
    end
  end

  context "recording instance methods" do
    let(:query) do
      <<-QUERY
      MATCH (a:Class{name: "A"})  -  [:OWNS]
        -> (ma:Method{type: "InstanceMethod", name: "some_method"})
      MATCH (b:Class{name: "B"})  -  [:OWNS]
        ->  (mb:Method{type: "InstanceMethod", name: "another_method"})
      MATCH (c:Class{name: "C"})  -  [:OWNS]
        ->  (mc:Method{type: "InstanceMethod", name: "method_with_no_more_method_calls"})

      RETURN
        count(ma), ma,
        count(mb), mb,
        count(mc), mc
      QUERY
    end

    it do
      a_method_count, method_a, b_method_count, method_b, c_method_count, method_c = result

      expect(a_method_count).to eq 1

      expect(method_a).to eq({
        "file" => "fixtures/a.rb",
        "line_number" => 3,
        "name" => "some_method",
        "type" => "InstanceMethod"
      })

      expect(b_method_count).to eq 1
      expect(c_method_count).to eq 1
    end
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
        Delfos.setup!(application_directories: ["./fixtures/sub_classes"])

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
