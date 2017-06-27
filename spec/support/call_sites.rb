# frozen_string_literal: true

module CallSiteHelpers
  def expect_these_call_sites(code, prefix: "fixtures/")
    index = 0

    expect(call_site_logger).to receive(:log) do |call_site|
      expect_call_sites(call_site, index, expected_call_sites, prefix)

      index += 1
    end.exactly(expected_call_sites.length).times

    load code
  end

  def expect_call_stack(call_stack, expected)
    call_stack.each_with_index do |cs, i|
      expect_call_sites(cs, i, expected)
    end
  end

  def expect_call_sites(call_site, index, expected, prefix = "fixtures/")
    expect_call_site(call_site, *expected[index], prefix)
  end

  def expect_call_site(call_site, container_summary, cs_summary, called_method_summary, prefix)
    expect(call_site.summary[:container_method]).to eq "#{prefix}#{container_summary}"
    expect(call_site.summary[:call_site])       .to eq "#{prefix}#{cs_summary}"
    expect(call_site.summary[:called_method])   .to eq "#{prefix}#{called_method_summary}"
  end
end

RSpec.configure do |c|
  c.include CallSiteHelpers
end
