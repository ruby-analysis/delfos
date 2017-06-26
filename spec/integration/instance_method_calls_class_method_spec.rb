# frozen_string_literal: true

require "delfos"

RSpec.describe "integration" do
  let(:call_site_logger) { double "call_site_logger", log: nil, save_call_stack: nil, finish!: nil }

  before(:each) do
    Delfos.configure do |c|
      c.include = "fixtures"
      c.call_site_logger = call_site_logger
      c.logger = DelfosSpecs.logger
    end
    Delfos.start!
  end

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
      index = 0

      expect(call_site_logger).to receive(:log) do |call_site|
        expect_call_sites(call_site, index, expected_call_sites)

        index += 1
      end.exactly(expected_call_sites.length).times

      load "./fixtures/instance_method_calls_a_class_method_usage.rb"
    end

    def expect_call_sites(call_site, index, _call_sites)
      expect_call_site(call_site, *expected_call_sites[index])
    end

    def expect_call_site(call_site, container_summary, cs_summary, called_method_summary)
      expect(call_site.summary[:container_method]).to eq "fixtures/#{container_summary}"
      expect(call_site.summary[:call_site])       .to eq "fixtures/#{cs_summary}"
      expect(call_site.summary[:called_method])   .to eq "fixtures/#{called_method_summary}"
    end
  end
end
