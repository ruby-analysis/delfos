# frozen_string_literal: true

require "delfos"

RSpec.describe "integration with a custom call_stack_logger" do
  include DelfosSpecs.stub_neo4j

  let(:cl) { Delfos::MethodTrace::CodeLocation }

  context "with distantly handled exceptions" do
    # rubocop:disable Metrics/BlockLength
    let(:expected_call_sites) do
      [
        [
          "with_distantly_handled_exception.rb:21 Object#(main)",
          "with_distantly_handled_exception.rb:21",
          "with_distantly_handled_exception.rb:1 Object#outer",
        ],
        [
          "with_distantly_handled_exception.rb:1 Object#outer",
          "with_distantly_handled_exception.rb:2",
          "with_distantly_handled_exception.rb:5 Object#inner",
        ],
        [
          "with_distantly_handled_exception.rb:5 Object#inner",
          "with_distantly_handled_exception.rb:6",
          "with_distantly_handled_exception.rb:9 Object#wait_for_it___",
        ],
        [
          "with_distantly_handled_exception.rb:9 Object#wait_for_it___",
          "with_distantly_handled_exception.rb:10",
          "with_distantly_handled_exception.rb:13 Object#boom",
        ],
        [
          "with_distantly_handled_exception.rb:23 Object#(main)",
          "with_distantly_handled_exception.rb:23",
          "with_distantly_handled_exception.rb:17 Object#another",
        ],
      ]
    end
    # rubocop:ensable Metrics/BlockLength

    it "still logs correctly" do
      expect_these_call_sites("./fixtures/with_distantly_handled_exception.rb")
    end
  end

  context "with code that raises and rescues" do
    let(:code_to_run) { "fixtures/with_raise.rb" }

    let(:expected_call_sites) do
      [
        [
          "with_raise.rb:13 Object#(main)",
          "with_raise.rb:13",
          "with_raise.rb:5 Object#execution_1",
        ],

        [
          "with_raise.rb:5 Object#execution_1",
          "with_raise.rb:6",
          "with_raise.rb:1 Object#boom",
        ],

        [
          "with_raise.rb:5 Object#execution_1",
          "with_raise.rb:7",
          "with_raise.rb:10 Object#another_method",
        ],

        [
          "with_raise.rb:14 Object#(main)",
          "with_raise.rb:14",
          "with_raise.rb:10 Object#another_method",
        ],
      ]
    end

    it "logs the call sites" do
      expect_these_call_sites "fixtures/with_raise.rb"
    end
  end
end
