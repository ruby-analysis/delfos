# frozen_string_literal: true

require "delfos"

RSpec.describe "integration" do
  include DelfosSpecs.stub_neo4j

  context "records call sites" do
    let(:expected_call_sites) do
      [
        ["a_usage.rb:3 Object#(main)",   "a_usage.rb:3",  "a.rb:5 A#some_method"],
        ["a.rb:5 A#some_method",         "a.rb:6",        "b.rb:3 B#another_method"],
        ["b.rb:3 B#another_method",      "b.rb:4",        "a.rb:11 A#to_s"],
        ["b.rb:3 B#another_method",      "b.rb:6",        "b.rb:33 C#method_with_no_more_method_calls"],
        ["b.rb:3 B#another_method",      "b.rb:8",        "b.rb:17 C#third"],
        ["b.rb:17 C#third",              "b.rb:18",       "b.rb:11 B#cyclic_dependency"],
        ["b.rb:11 B#cyclic_dependency",  "b.rb:12",       "b.rb:21 C#fourth"],
        ["b.rb:21 C#fourth",             "b.rb:22",       "b.rb:25 C#fifth"],
        ["b.rb:25 C#fifth",              "b.rb:26",       "b.rb:29 C#sixth"],
        # first execution chain ends here

        ["a.rb:5 A#some_method",         "a.rb:7",        "b.rb:33 C#method_with_no_more_method_calls"],
        # 2nd execution chain ends here

        ["a.rb:5 A#some_method",         "a.rb:8",        "a.rb:21 D.some_class_method"],
        # 3rd execution chain ends here
      ]
    end

    it do
      index = 0
      expect(call_site_logger).to receive(:log) do |call_site|
        expect_call_sites(call_site, index, expected_call_sites)

        index += 1
      end.exactly(expected_call_sites.length).times

      load "./fixtures/a_usage.rb"
    end
  end
end
