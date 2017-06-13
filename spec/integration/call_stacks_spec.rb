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
        ["a_usage_2.rb:0 Object#(main)", "a_usage_2.rb:3", "a.rb:5 A#some_method"],
        ["a.rb:5 A#some_method",         "a.rb:6",         "b.rb:3 B#another_method"],
        ["b.rb:3 B#another_method",      "b.rb:4",         "b.rb:3 B#another_method"],
      ]
    end

    let(:expected_call_stack_2) do
      [
        ["a_usage_2.rb:0 Object#(main)", "a_usage_2.rb:4", "a.rb:11 A#to_s"],
      ]
    end

    it do
      index = 0

      expect(call_site_logger).to receive(:save_call_stack) do |call_sites, execution_number|
        index += 1
        expect(execution_number).to eq index

        case index
        when 1
          expect_call_stack(call_stack, index, expected_call_stack_1)
        when 2
          expect_call_stack(call_stack, index, expected_call_stack_2)
        end

      end.exactly(2).times

      load "./fixtures/a_usage_2.rb"
    end

    def expect_call_stack(call_stack, expected)
      call_stack.each_with_index do |cs, i|
        expect_call_sites(cs, i, expected)
      end
    end

    def expect_call_sites(call_site, index, expected)
      expect_call_site(call_site, *expected[index])
    end

    def expect_call_site(call_site, container_summary, cs_summary, called_method_summary)
      expect(call_site.summary[:container_method]).to eq "fixtures/#{container_summary}"
      expect(call_site.summary[:call_site])       .to eq "fixtures/#{cs_summary}"
      expect(call_site.summary[:called_method])   .to eq "fixtures/#{called_method_summary}"
    end
  end
end
