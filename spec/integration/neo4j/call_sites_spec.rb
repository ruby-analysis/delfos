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
    Delfos::Neo4j.execute_sync(query).first
  end

  before(:each) do
    wipe_db!

    Delfos.setup!(application_directories: ["fixtures"], logger: $delfos_test_logger)

    load "./fixtures/a_usage.rb"
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
      Delfos.flush!

      call_site_1_count, call_site_2_count, call_site_3_count =
        result

      byebug
      expect(call_site_1_count).to eq 1
      expect(call_site_2_count).to eq 1
      expect(call_site_3_count).to eq 1
    end
  end
end
