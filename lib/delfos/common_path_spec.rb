require_relative "common_path"

describe Delfos::CommonPath do
  describe "#included_in?" do
    it "determines the common paths" do
      result = described_class.included_in?("/a/b/c/d", ["/a/b/c/d/e", "/b"])
      expect(result).to be_falsey
    end

    it "works with a single path" do
      result = described_class.included_in?("/a/b/c/d", ["/q"])
      expect(result).to be_falsey
    end

    it "works with a single path" do
      result = described_class.included_in?("/a/b/c/d", ["/a"])
      expect(result).to be_truthy
    end

    it "determines the common paths" do
      result = described_class.included_in?("/b/c/d", ["/a/b", "/b"])
      expect(result).to be_truthy
    end
  end

  it "determines the common path" do
    #common is LHS value
    result = described_class.common_parent_directory_path("/a/b/c/d", "/a/b/c/d/e")
    expect(result.to_s).to eq "/a/b/c/d"

    #common is RHS value
    result = described_class.common_parent_directory_path("/a/b/c", "/a/b")
    expect(result.to_s).to eq "/a/b"

    #common is neither LHS nor RHS
    result = described_class.common_parent_directory_path("/a/b/c/d", "/a/b/e/f")
    expect(result.to_s).to eq "/a/b"

    #both paths same
    result = described_class.common_parent_directory_path("/a/b", "/a/b")
    expect(result.to_s).to eq "/a/b"
  end

  it "handles the root path case" do
    result = described_class.common_parent_directory_path("/a/b/c/d", "/e/f")
    expect(result.to_s).to eq "/"
  end
end
