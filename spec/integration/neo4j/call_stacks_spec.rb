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
    load "./fixtures/a_usage.rb"
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
end
