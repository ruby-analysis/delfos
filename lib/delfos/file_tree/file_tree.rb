require_relative "distance_calculation"

module FileTree
  class FileTree
    attr_reader :path

    def initialize(path)
      @path = path
    end

    def files
      @files ||= instantiate_sub_tree(:file?)
    end

    def directories
      @directories ||= instantiate_sub_tree(:directory?)
    end

    def distance_to(other)
      DistanceCalculation.new(self, other)
    end

    private

    def instantiate_sub_tree(type)
      glob.select(&type).map{|d| self.class.new(d.to_s) }
    end

    def glob
      Dir.glob(path + "/*").map{|f| Pathname.new(f)}
    end
  end
end
