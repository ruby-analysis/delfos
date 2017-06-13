# frozen_string_literal: true

require "delfos"
require "delfos/neo4j"

describe "integration with default neo4j logging" do
  let(:result) do
    Delfos.flush!
    Delfos::Neo4j.execute_sync(query).first
  end

  before(:each) do
    wipe_db!

    Delfos.setup!(application_directories: ["fixtures"], logger: $delfos_test_logger)
    load "fixtures/a_usage.rb"
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
                             "line_number" => 5,
                             "name" => "some_method",
                             "type" => "InstanceMethod")

      expect(b_method_count).to eq 1
      expect(c_method_count).to eq 1
    end
  end
end
