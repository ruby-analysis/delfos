# frozen_string_literal: true
require_relative "calculation"

describe Delfos::Distance::Calculation do
  let(:distance_calculation) { described_class.new(a, b) }

  describe "#traversal_path" do
    let(:a) { t("tree/another_top_level_file") }
    let(:b) { t("tree/yet_another_file") }

    it do
      expect(distance_calculation.traversal_path).to eq [
        expand_fixture_path("tree/another_top_level_file"),
        expand_fixture_path("tree/yet_another_file"),
      ]
    end

    context do
      let(:a) { t("tree/some_file") }
      let(:b) { t("tree/sub_directory/file_in_sub_directory") }

      it do
        result = distance_calculation.traversal_path

        expect(result).to eq [
          expand_fixture_path("tree/some_file"),
          expand_fixture_path("tree/sub_directory"),
          expand_fixture_path("tree/sub_directory/file_in_sub_directory"),
        ]
      end
    end
  end

  describe "#traversals" do
    let(:a) { t("tree/some_file") }
    let(:b) { t("tree/sub_directory/file_in_sub_directory") }

    it do
      expect(distance_calculation.traversals.map(&:class)).to eq [
        Delfos::Distance::Relation,
        Delfos::Distance::ChildFile,
      ]

      files = distance_calculation.traversals.first.traversed_files

      match_file_array files, %w(
        tree/some_file
        tree/even_more
        tree/another_top_level_file
      )
    end

    it do
      files = distance_calculation.traversals.last.traversed_files

      match_file_array files, %w(
        tree/sub_directory/even_more
        tree/sub_directory/file_in_sub_directory
      )

      expect(distance_calculation.traversals.map(&:distance)).to match_array [
        3 + 2, # files then directories
        3 + 2, # directories then files
      ]
    end
  end

  describe "#traversals" do
    let(:a) { t("tree/another_top_level_file") }
    let(:b) { t("tree/yet_another_file") }

    it do
      expect(distance_calculation.traversals.map(&:class)).to eq [
        Delfos::Distance::Relation,
      ]
    end

    context do
      let(:a) { t("tree/sub_directory/file_in_sub_directory") }
      let(:b) { t("tree/another_sub_directory/another_file") }

      it do
        expect(distance_calculation.traversals.map(&:class)).to eq [
          Delfos::Distance::Relation,
          Delfos::Distance::Relation,
          Delfos::Distance::ChildFile,
        ]
      end
    end
  end

  describe "#sum_traversals" do
    let(:a) { t("tree/another_top_level_file") }
    let(:b) { t("tree/yet_another_file") }

    it do
      expect(distance_calculation.sum_traversals).to eq 4
    end
  end

  describe "#sum_possible_traversals" do
    let(:a) { t("tree/another_top_level_file") }
    let(:b) { t("tree/yet_another_file") }

    it do
      expect(distance_calculation.sum_possible_traversals).to eq 4 + 3
    end
  end
end
