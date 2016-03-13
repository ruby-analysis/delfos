# frozen_string_literal: true
require_relative "file_tree"
require "byebug"

describe Delfos::FileTree::FileTree do
  let(:tree) { described_class.new "./fixtures/tree" }

  it do
    expect(tree.path).to eq "./fixtures/tree"
  end

  it do
    expect(tree.files.map(&:path)).to eq [
      "./fixtures/tree/another_top_level_file",
      "./fixtures/tree/even_more",
      "./fixtures/tree/some_file",
      "./fixtures/tree/yet_another_file",
    ]
  end

  it do
    expect(tree.directories.map(&:path)).to eq [
      "./fixtures/tree/another_sub_directory",
      "./fixtures/tree/sub_directory",
      "./fixtures/tree/yet_another_directory",
    ]
  end

  describe "#distance_to" do
    let(:b) { described_class.new("./fixtures/tree/yet_another_file") }
    let(:a) { described_class.new("./fixtures/tree/another_top_level_file") }

    it do
      distance = a.distance_to(b)
    end
  end
end
