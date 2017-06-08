# frozen_string_literal: true
require "delfos"
require "delfos/neo4j"
require "./fixtures/b.rb"
require "./fixtures/a.rb"
require "./fixtures/sub_classes/sub_classes.rb"
require "./fixtures/class_method_calls_instance_method.rb"
require "./fixtures/instance_method_calls_class_method.rb"

describe "integration with default neo4j logging" do
  let(:result) do
    Delfos::Neo4j.flush!
    Delfos::Neo4j.execute_sync(query).first
  end

  before(:each) do
    wipe_db!

    Delfos.setup!(application_directories: ["fixtures"], logger: $delfos_test_logger)
  end

  after do
    Delfos.reset!
  end

  context "with a and b fixture files" do
    before(:each) do
      a = A.new
      a.some_method
      Delfos::Neo4j.flush!
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

        expect(method_a).to eq("file" => "fixtures/a.rb",
                               "line_number" => 3,
                               "name" => "some_method",
                               "type" => "InstanceMethod")

        expect(b_method_count).to eq 1
        expect(c_method_count).to eq 1
      end
    end
  end

  context "class method calls an instance method" do
    before(:each) do
      ClassMethodCallsAnInstanceMethod.a_class_method

      Delfos::Neo4j.flush!
    end

    let(:query) do
      <<-QUERY
          MATCH (a:Class{name: "ClassMethodCallsAnInstanceMethod"})  -  [:OWNS]
            -> (ma:Method{type: "ClassMethod", name: "a_class_method"})

          MATCH (b:Class{name: "HasInstanceMethod"})  -  [:OWNS]
            ->  (mb:Method{type: "InstanceMethod", name: "an_instance_method"})

          MATCH (ma)-[:CONTAINS]->(cs:CallSite)-[:CALLS]->(mb)

      RETURN
        count(ma), ma,
        count(mb), mb,
        count(cs), cs
      QUERY
    end

    it do
      a_method_count, method_a, b_method_count, method_b, call_site_count, call_site = result

      expect(a_method_count).to eq 1

      expect(method_a).to eq("file" => "fixtures/class_method_calls_instance_method.rb",
                             "line_number" => 2,
                             "name" => "a_class_method",
                             "type" => "ClassMethod")

      expect(b_method_count).to eq 1

      expect(method_b).to eq("file" => "fixtures/class_method_calls_instance_method.rb",
                             "line_number" => 8,
                             "name" => "an_instance_method",
                             "type" => "InstanceMethod")

      expect(call_site_count).to eq 1

      expect(call_site).to eq("file" => "fixtures/class_method_calls_instance_method.rb",
                              "line_number" => 3)
    end
  end

  context "instance method calls a class method" do
    before(:each) do
      InstanceMethodCallsAClassMethod.new.an_instance_method

      Delfos::Neo4j.flush!
    end

    let(:query) do
      <<-QUERY
          MATCH (a:Class{name: "InstanceMethodCallsAClassMethod"})  -  [:OWNS]
            -> (ma:Method{type: "InstanceMethod", name: "an_instance_method"})

          MATCH (b:Class{name: "HasClassMethod"})  -  [:OWNS]
            ->  (mb:Method{type: "ClassMethod", name: "a_class_method"})

          MATCH (ma)-[:CONTAINS]->(cs:CallSite)-[:CALLS]->(mb)

      RETURN
        count(ma), ma,
        count(mb), mb,
        count(cs), cs
      QUERY
    end

    it do
      a_method_count, method_a, b_method_count, method_b, call_site_count, call_site = result

      expect(a_method_count).to eq 1

      expect(method_a).to eq("file" => "fixtures/instance_method_calls_class_method.rb",
                             "line_number" => 2,
                             "name" => "an_instance_method",
                             "type" => "InstanceMethod")

      expect(b_method_count).to eq 1

      expect(method_b).to eq("file" => "fixtures/instance_method_calls_class_method.rb",
                             "line_number" => 8,
                             "name" => "a_class_method",
                             "type" => "ClassMethod")

      expect(call_site_count).to eq 1

      expect(call_site).to eq("file" => "fixtures/instance_method_calls_class_method.rb",
                              "line_number" => 3)
    end
  end

  context "with a call to super inside new" do
    context "without Delfos enabled" do
      it do
        expect(SomeKlass).to be_a Class
        expect(SomeSubKlass).to be_a Class

        expect(SomeKlass.new).to be_a SomeSubKlass
      end
    end

    context "with Delfos enabled" do
      before do
        Delfos.setup!(application_directories: ["./fixtures/sub_classes"])
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
