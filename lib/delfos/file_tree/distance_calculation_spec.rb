# frozen_string_literal: true
require_relative "file_tree"
require_relative "distance_calculation"

describe Delfos::FileTree::DistanceCalculation do
  let(:distance_calculation) { described_class.new(a, b) }

  describe "#traversal_path" do
    let(:a) { t("another_top_level_file") }
    let(:b) { t("yet_another_file") }

    it do
      expect(distance_calculation.traversal_path).to eq [
        expand_fixture_path("another_top_level_file"),
        expand_fixture_path("yet_another_file"),
      ]
    end

    context do
      let(:a) { t("some_file") }
      let(:b) { t("sub_directory/file_in_sub_directory") }

      it do
        result = distance_calculation.traversal_path

        expect(result).to eq [
          expand_fixture_path("some_file"),
          expand_fixture_path("/sub_directory"),
          expand_fixture_path("/sub_directory/file_in_sub_directory"),
        ]
      end
    end
  end

  describe "#traversals" do
    let(:a) { t("some_file") }
    let(:b) { t("sub_directory/file_in_sub_directory") }

    it do
      expect(distance_calculation.traversals.map(&:class)).to eq [
        Delfos::FileTree::Relation,
        Delfos::FileTree::ChildFile,
      ]

      files = distance_calculation.traversals.first.traversed_files

      match_file_array files, %w(
        some_file
        even_more
        another_top_level_file
      )
    end

    it do
      files = distance_calculation.traversals.last.traversed_files

      match_file_array files, %w(
        sub_directory/even_more
        sub_directory/file_in_sub_directory
      )

      expect(distance_calculation.traversals.map(&:distance)).to match_array [
        3 + 2, # files then directories
        3 + 2, # directories then files
      ]
    end
  end

  describe "#traversals" do
    let(:a) { t("another_top_level_file") }
    let(:b) { t("yet_another_file") }

    it do
      expect(distance_calculation.traversals.map(&:class)).to eq [
        Delfos::FileTree::Relation,
      ]
    end

    context do
      let(:a) { t("sub_directory/file_in_sub_directory") }
      let(:b) { t("another_sub_directory/another_file") }

      it do
        expect(distance_calculation.traversals.map(&:class)).to eq [
          Delfos::FileTree::Relation,
          Delfos::FileTree::Relation,
          Delfos::FileTree::ChildFile,
        ]
      end
    end
  end

  describe "#sum_traversals" do
    let(:a) { t("another_top_level_file") }
    let(:b) { t("yet_another_file") }

    it do
      expect(distance_calculation.sum_traversals).to eq 4
    end
  end

  describe "#sum_possible_traversals" do
    let(:a) { t("another_top_level_file") }
    let(:b) { t("yet_another_file") }

    it do
      expect(distance_calculation.sum_possible_traversals).to eq 4 + 3
    end
  end
end
