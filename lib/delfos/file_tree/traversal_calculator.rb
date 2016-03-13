require "pathname"
require_relative "relation"

module Delfos
  module FileTree
    class TraversalCalculator
      def traversals_for(a, b)
        return ChildFile if (b + ".." == a)

        Relation
      end
    end
  end
end
