# frozen_string_literal: true

require "delfos"

RSpec.describe "integration with a custom call_stack_logger" do
  include DelfosSpecs.stub_neo4j(include_path: "fixtures/app/include_this")

  context "with app code calling lib code which calls back into lib code" do
    let(:expected_call_sites) do
      [
        [
          "include_this/start_here.rb:3 Object#(main)",
          "include_this/start_here.rb:3",
          "include_this/called_app_class.rb:5 IncludeThis::CalledAppClass#some_called_method",
        ],
        [
          "exclude_this/exclude_this.rb:10 ExcludeThis#further",
          "exclude_this/exclude_this.rb:11",
          "include_this/called_app_class.rb:9 IncludeThis::CalledAppClass#next_method",
        ],
        [
          "include_this/called_app_class.rb:9 IncludeThis::CalledAppClass#next_method",
          "include_this/called_app_class.rb:10",
          "include_this/called_app_class.rb:13 IncludeThis::CalledAppClass#penultimate",
        ],
        [
          "include_this/called_app_class.rb:13 IncludeThis::CalledAppClass#penultimate",
          "include_this/called_app_class.rb:14",
          "include_this/called_app_class.rb:17 IncludeThis::CalledAppClass#final_method",
        ],
      ]
    end

    it do
      index = 0

      expect(call_site_logger).to receive(:log) do |call_site|
        expect_call_sites(call_site, index, expected_call_sites, "")

        index += 1
      end.exactly(expected_call_sites.length).times

      load "./fixtures/app/include_this/start_here.rb"
    end
  end
end
