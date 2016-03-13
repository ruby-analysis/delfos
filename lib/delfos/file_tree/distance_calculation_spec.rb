require_relative "file_tree"
require_relative "distance_calculation"

describe FileTree::DistanceCalculation do
  let(:distance_calculation) { described_class.new(a,b) }

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

  describe "#remove_traversals_from_files_to_parents_then_back_down_to_sub_directories" do
    let(:a) { t("some_file") }
    let(:b) { t("sub_directory/file_in_sub_directory") }


    it do
      result = distance_calculation.remove_traversals_from_files_to_parents_then_back_down_to_sub_directories [
        expand_fixture_path("some_file"),
        expand_fixture_path(""),
        expand_fixture_path("/sub_directory"),
      ]

      expect(result).to eq [
        expand_fixture_path("some_file"),
        expand_fixture_path("/sub_directory"),
      ]
    end

    it do
      result = distance_calculation.remove_traversals_from_files_to_parents_then_back_down_to_sub_directories [
        expand_fixture_path("another_sub_directory/another_file"),
        expand_fixture_path("another_sub_directory"),
        expand_fixture_path("another_sub_directory/yet_another_file"),
        expand_fixture_path("another_sub_directory"),
        expand_fixture_path("."),
        expand_fixture_path("sub_directory"),
      ]

      expect(result).to eq [
        expand_fixture_path("another_sub_directory/another_file"),
        expand_fixture_path("another_sub_directory/yet_another_file"),
        expand_fixture_path("another_sub_directory"),
        expand_fixture_path("sub_directory"),
      ]
    end

    it do
      result = distance_calculation.remove_traversals_from_files_to_parents_then_back_down_to_sub_directories [
        expand_fixture_path(""),
        expand_fixture_path("/sub_directory"),
      ]

      expect(result).to eq [
        expand_fixture_path(""),
        expand_fixture_path("/sub_directory"),
      ]
    end
  end

  describe "#traversals" do
    let(:a) { t("some_file") }
    let(:b) { t("sub_directory/file_in_sub_directory") }

    it do
      expect(distance_calculation.traversals.map(&:class)).to eq [
        FileTree::Relation,
        FileTree::ChildFile
      ]

      files = distance_calculation.traversals.first.traversed_files

      match_file_array files, %w[
        some_file
        even_more
        another_top_level_file
      ]
    end

    it do
      files = distance_calculation.traversals.last.traversed_files

      match_file_array files, %w[
        sub_directory/even_more
        sub_directory/file_in_sub_directory
      ]

      expect(distance_calculation.traversals.map(&:distance)).to match_array [
        3 + 2, #files then directories
        3 + 2, #directories then files
      ]
    end
  end


  describe "#traversals" do
    let(:a) { t("another_top_level_file") }
    let(:b) { t("yet_another_file") }

    it do
      expect(distance_calculation.traversals.map(&:class)).to eq [
        FileTree::Relation
      ]
    end

    context do
      let(:a) { t("sub_directory/file_in_sub_directory") }
      let(:b) { t("another_sub_directory/another_file") }

      it do
        expect(distance_calculation.traversals.map(&:class)).to eq [
          FileTree::Relation,
          FileTree::Relation,
          FileTree::ChildFile
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

  describe "#top_ancestor" do
    let(:a) { t("some_file") }
    let(:b) { t("sub_directory/file_in_sub_directory") }

    it do
      result = distance_calculation.top_ancestor

      expect(result).to eq fixture_path
    end
  end
end

