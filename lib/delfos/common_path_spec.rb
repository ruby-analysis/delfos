require_relative "common_path"

describe Delfos::CommonPath do
  it "determines the common path" do
    #common is LHS value 
    result = described_class.common_parent_directory_path("a/b/c/d", "a/b/c/d/e")
    expect(result.to_s).to eq "a/b/c/d"

    #common is RHS value 
    result = described_class.common_parent_directory_path("a/b/c", "a/b")
    expect(result.to_s).to eq "a/b"

    #common is neither LHS nor RHS
    result = described_class.common_parent_directory_path("a/b/c/d", "a/b/e/f")
    expect(result.to_s).to eq "a/b"

    #both paths same
    result = described_class.common_parent_directory_path("a/b", "a/b")
    expect(result.to_s).to eq "a/b"
  end

  it "handles the root path case" do
    result = described_class.common_parent_directory_path("/a/b/c/d", "/e/f")
    expect(result.to_s).to eq "/"
  end
end
