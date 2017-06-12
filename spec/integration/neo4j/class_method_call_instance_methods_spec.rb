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
    Delfos.flush!
    Delfos::Neo4j.execute_sync(query).first
  end

  before(:each) do
    wipe_db!

    Delfos.setup!(application_directories: ["fixtures"], logger: $delfos_test_logger)
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
end