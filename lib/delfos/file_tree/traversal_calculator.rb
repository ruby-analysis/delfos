require "pathname"
require_relative "relation"

module FileTree
  class TraversalCalculator
    def traversals_for(a, b)
      return ChildFile if (b + ".." == a)

      Relation
    end
  end
end
