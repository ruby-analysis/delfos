# This happens in bundler

RSpec.describe "integration - undefing an aliased method" do
  include DelfosSpecs.stub_neo4j(include_path: "fixtures")

  let(:expected_call_sites) do
    [
      [
        "fixtures/undef/alias_and_undef_super_method.rb:16 Object#(main)",
        "fixtures/undef/alias_and_undef_super_method.rb:16",
        "fixtures/undef/alias_and_undef_super_method.rb:10 SubClass#calls_a_method",
      ],
      [
        "fixtures/undef/alias_and_undef_super_method.rb:10 SubClass#calls_a_method",
        "fixtures/undef/alias_and_undef_super_method.rb:11",
        "fixtures/undef/alias_and_undef_super_method.rb:2 SubClass#a_method",
      ],
    ]
  end

  it do
    index = 0

    expect(call_site_logger).to receive(:log) do |call_site|
      expect_call_sites(call_site, index, expected_call_sites, "")

      index += 1
    end.exactly(expected_call_sites.length).times

    load "./fixtures/undef/alias_and_undef_super_method.rb"
  end
end
