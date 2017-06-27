# frozen_string_literal: true

# This happens in bundler

RSpec.describe "integration - undefing an aliased method" do
  include DelfosSpecs.stub_neo4j include_path: "fixtures/undef"

  let(:expected_call_sites) do
    [
      [
        "alias_and_undef_super_method.rb:16 Object#(main)",
        "alias_and_undef_super_method.rb:16",
        "alias_and_undef_super_method.rb:10 SubClass#calls_a_method",
      ],
      [
        "alias_and_undef_super_method.rb:10 SubClass#calls_a_method",
        "alias_and_undef_super_method.rb:11",
        "alias_and_undef_super_method.rb:2 SubClass#a_method",
      ],
    ]
  end

  it do
    expect_these_call_sites("./fixtures/undef/alias_and_undef_super_method.rb", prefix: "undef/")
  end
end
