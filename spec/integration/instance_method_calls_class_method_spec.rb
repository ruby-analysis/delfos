# frozen_string_literal: true

require "delfos"

RSpec.describe "integration" do
  include DelfosSpecs.stub_neo4j

  context "instance method calls a class method" do
    let(:expected_call_sites) do
      [
        [
          "instance_method_calls_a_class_method_usage.rb:3 Object#(main)",
          "instance_method_calls_a_class_method_usage.rb:3",
          "instance_method_calls_a_class_method.rb:2 InstanceMethodCallsAClassMethod#an_instance_method",
        ],
        [
          "instance_method_calls_a_class_method.rb:2 InstanceMethodCallsAClassMethod#an_instance_method",
          "instance_method_calls_a_class_method.rb:3",
          "instance_method_calls_a_class_method.rb:8 HasClassMethod.a_class_method",
        ],
      ]
    end

    it do
      expect_these_call_sites("./fixtures/instance_method_calls_a_class_method_usage.rb")
    end
  end
end
