# frozen_string_literal: true
require_relative "relation"

describe Delfos::FileTree::Relation do
  describe "#others" do
    let(:relation) { described_class.new(path, anything) }

    context "with a file" do
      let(:path) { t("another_top_level_file") }

      it "returns just files" do
        result = relation.other_files

        match_file_array result, %w(
          another_top_level_file
          even_more
          some_file
          yet_another_file
        )
      end

      it "returns just directories" do
        result = relation.other_directories

        match_file_array result, %w(
          another_sub_directory
          sub_directory
          yet_another_directory
        )
      end
    end

    context "with a directory" do
      let(:path) { t("sub_directory") }

      it "returns just files" do
        result = relation.other_files

        match_file_array result, %w(
          another_top_level_file
          even_more
          some_file
          yet_another_file
        )
      end

      it "returns just directories" do
        result = relation.other_directories

        match_file_array result, %w(
          another_sub_directory
          sub_directory
          yet_another_directory
        )
      end
    end
  end

  # ▾ fixtures/
  #  ▾ tree/
  #    ▾ another_sub_directory/
  #        another_file
  #        yet_another_file
  #    ▾ sub_directory/
  #      ▸ another_directory/
  #      ▸ second_level/
  #      ▸ yet_another_directory/
  #        even_more
  #        file_in_sub_directory
  #        some_more
  #    ▸ yet_another_directory/
  #      another_top_level_file
  #      even_more
  #      some_file
  #      yet_another_file
end

describe Delfos::FileTree::Relation do
  let(:instance) { described_class.new(a, b) }
  let(:a) { t("sub_directory/file_in_sub_directory") }
  let(:b) { t("sub_directory") }

  describe "#subset_to_traverse" do
    it "whole collection" do
      result = instance.subset_to_traverse(
        collection: [1, 2, 3, 4], start: 1, finish: 4,
      )

      expect(result).to eq [1, 2, 3, 4]
    end

    it "with missing finish" do
      result = instance.subset_to_traverse(
        collection: [1, 2, 3, 4], start: 1, finish: 5,
      )

      expect(result).to eq [1, 2, 3, 4]
    end

    it "return directories from file to directory " do
      file1 = double "file1", file?: true, directory?: false
      dir2 = double "dir2", file?: false, directory?: true

      result = instance.subset_to_traverse(
        collection: ["dir1", dir2, "dir3", "dir4"],
        start: file1, finish: dir2, start_at_end: true
      )

      expect(result).to eq [dir2, "dir3", "dir4"]
    end

    it "return directories from file to directory " do
      file1 = double "file1", file?: true, directory?: false
      dir2 = double "dir2", file?: false, directory?: true

      result = instance.subset_to_traverse(
        collection: ["dir1", dir2, "dir3", "dir4"],
        start: file1, finish: dir2
      )

      expect(result).to eq [dir2, "dir3", "dir4"]
    end

    it "with both missing" do
      result = instance.subset_to_traverse(
        collection: [1, 2, 3, 4], start: 10, finish: 5,
      )

      expect(result).to eq [1, 2, 3, 4]
    end

    it "all reversed order" do
      result = instance.subset_to_traverse(
        collection: [1, 2, 3, 4], start: 4, finish: 1,
      )

      expect(result).to eq [1, 2, 3, 4]
    end

    it "subset" do
      result = instance.subset_to_traverse(
        collection: [1, 2, 3, 4], start: 2, finish: 3,
      )

      expect(result).to eq [2, 3]
    end

    it "subset until last element" do
      result = instance.subset_to_traverse(
        collection: [1, 2, 3, 4], start: 2, finish: 4,
      )

      expect(result).to eq [2, 3, 4]
    end

    it "reversed subset" do
      result = instance.subset_to_traverse(
        collection: [1, 2, 3, 4], start: 3, finish: 2,
      )

      expect(result).to eq [2, 3]
    end

    it "reversed subset from last element" do
      result = instance.subset_to_traverse(
        collection: [1, 2, 3, 4], start: 4, finish: 2,
      )

      expect(result).to eq [2, 3, 4]
    end
  end

  it do
    match_file_array instance.other_files, %w(
      sub_directory/some_more
      sub_directory/even_more
      sub_directory/file_in_sub_directory
    )
  end

  context "traversing all files" do
    let(:a) { t("sub_directory/some_more") }
    let(:b) { t("sub_directory") }

    it do
      match_file_array instance.traversed_files, %w(
        sub_directory/some_more
        sub_directory/even_more
        sub_directory/file_in_sub_directory
      )
    end
  end

  context "traversing some files" do
    let(:a) { t("sub_directory/file_in_sub_directory") }
    let(:b) { t("sub_directory") }

    it do
      match_file_array instance.traversed_files, %w(
        sub_directory/even_more
        sub_directory/file_in_sub_directory
      )
    end
  end

  context "traversing up some files" do
    let(:a) { t("sub_directory/some_more") }
    let(:b) { t("sub_directory/file_in_sub_directory") }

    it do
      match_file_array instance.traversed_files, %w(
        sub_directory/some_more
        sub_directory/file_in_sub_directory
      )
    end
  end

  it do
    match_file_array instance.other_directories, %w(
      sub_directory/another_directory/
      sub_directory/second_level/
      sub_directory/yet_another_directory/
    )
  end

  context "traversing up some directories" do
    let(:a) { t("sub_directory/file_in_sub_directory") }
    let(:b) { t("sub_directory/second_level") }

    it do
      match_file_array instance.traversed_directories, %w(
        sub_directory/yet_another_directory
        sub_directory/second_level
      )
    end
  end

  context "traversing down all directories" do
    let(:a) { t("sub_directory/another_directory") }
    let(:b) { t("sub_directory/yet_another_directory") }

    it do
      match_file_array instance.traversed_directories, %w(
        sub_directory/another_directory
        sub_directory/second_level
        sub_directory/yet_another_directory
      )
    end
  end

  context "traversing down some directories" do
    let(:a) { t("sub_directory/another_directory") }
    let(:b) { t("sub_directory/second_level") }

    it do
      match_file_array instance.traversed_directories, %w(
        sub_directory/another_directory
        sub_directory/second_level
      )
    end
  end

  context "traversing down some directories" do
    let(:a) { t("sub_directory/second_level") }
    let(:b) { t("sub_directory/yet_another_directory") }

    it do
      match_file_array instance.traversed_directories, %w(
        sub_directory/second_level
        sub_directory/yet_another_directory
      )
    end
  end
  context "traversing all directories" do
    let(:a) { t("sub_directory/file_in_sub_directory") }
    let(:b) { t("sub_directory/another_directory") }

    it do
      match_file_array instance.traversed_directories, %w(
        sub_directory/another_directory/
        sub_directory/second_level/
        sub_directory/yet_another_directory/
      )
    end
  end
end
