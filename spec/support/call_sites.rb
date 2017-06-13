module CallSiteHelpers
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

RSpec.configure do |c|
  c.include CallSiteHelpers
end
