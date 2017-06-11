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

  context "instance method calls a class method" do
    before(:each) do
      InstanceMethodCallsAClassMethod.new.an_instance_method
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
end
