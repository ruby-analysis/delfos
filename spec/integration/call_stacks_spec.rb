# frozen_string_literal: true

require "delfos"
require "delfos/neo4j"

describe "integration" do
  let(:call_site_logger) { double "call_site_logger", log: nil, save_call_stack: nil }

  before(:each) do
    Delfos.setup!(application_directories: ["fixtures"],
                  call_site_logger: call_site_logger,
                  logger: $delfos_test_logger)
  end

  context "recording call stacks" do
    let(:expected_call_stack_1) do
      [
        ["a_usage_3.rb:0 Object#(main)", "a_usage_3.rb:3", "a.rb:11 A#to_s"],
        # etc

      ]
    end

    let(:expected_call_stack_2) do
      [
        ["a_usage_3.rb:0 Object#(main)", "a_usage_3.rb:4", "a.rb:11 A#to_s"],
      ]
    end

    it do
      index = 0

      expect(call_site_logger).to receive(:save_call_stack) do |call_stack, execution_number|
        index += 1
        expect(execution_number).to eq index

        case index
        when 1
          expect_call_stack(call_stack, expected_call_stack_1)
        when 2
          expect_call_stack(call_stack, expected_call_stack_2)
        end
      end.exactly(2).times

      load "./fixtures/a_usage_3.rb"
    end
  end
end
