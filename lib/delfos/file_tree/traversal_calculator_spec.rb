require_relative "traversal_calculator"

describe FileTree::TraversalCalculator do
  describe "#traversals_for" do
    it "file to file" do
      result = subject.traversals_for(t("another_top_level_file"), t("yet_another_file"))
      expect(result).to eq FileTree::Relation
    end

    it "directory to parent directory" do
      expect(subject.traversals_for(t("sub_directory"),t("."))).
        to eq FileTree::Relation
    end

    it "file to file in sub directory" do
      expect(subject.traversals_for(t("some_file"),t("sub_directory"))).
        to eq FileTree::Relation

      expect(subject.traversals_for(t("sub_directory"),t("sub_directory/file_in_sub_directory"))).
        to eq FileTree::ChildFile
    end

    it "directory to sibling directory" do
      expect(subject.traversals_for(t("sub_directory"),t("another_sub_directory"))).
        to eq FileTree::Relation 
    end

    it "file to directory" do
      expect(subject.traversals_for(t("some_file"),t("."))).
        to eq FileTree::Relation
    end

    it "directory to file" do
      expect(subject.traversals_for(t("."),t("some_file"))).
        to eq FileTree::ChildFile
    end

    it "sub directory to file" do
      expect(subject.traversals_for(t("sub_directory"),t("some_file"))).
        to eq FileTree::Relation
    end

    it "file to sub directory" do
      expect(subject.traversals_for(t("some_file"),t("sub_directory"))).
        to eq FileTree::Relation
    end


  end
end
