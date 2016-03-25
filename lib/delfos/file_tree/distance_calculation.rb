# frozen_string_literal: true
require_relative "traversal_calculator"

module Delfos
  module FileTree
    class DistanceCalculation
      attr_reader :path_a, :path_b

      def initialize(path_a, path_b)
        @path_a = path_a
        @path_b = path_b
      end

      attr_reader :traversal_a, :traversal_b

      def traversals_for(a, b)
        TraversalCalculator.new.traversals_for(a, b)
      end

      def traversals
        result = []
        path = traversal_path

        path.each_cons(2) do |start, finish|
          klass = traversals_for(start, finish)
          result.push(klass.new(start, finish))
        end

        result
      end

      def sum_traversals
        traversals.inject(0) { |sum, i| sum + i.distance }
      end

      def sum_possible_traversals
        traversals.inject(0) { |sum, i| sum + i.possible_length }
      end

      def sibling_directories(path)
        siblings(path).select { |f| File.directory?(f) }
      end

      def in_start_directory?(path)
        return false if path.directory?
        path_a.dirname == path
      end

      def in_finish_directory?(path)
        return false if path.directory?

        path_b.dirname == path
      end

      def top_ancestor
        common_directory_path(path_a, path_b)
      end

      def common_directory_path(path_a, path_b)
        separator = "/"
        dirs = [path_a.to_s, path_b.to_s]

        dir1, dir2 = dirs.minmax.map { |dir| dir.split(separator) }

        path = dir1.
               zip(dir2).
               take_while { |dn1, dn2| dn1 == dn2 }.
               map(&:first).
               join(separator)

        Pathname.new(path)
      end

      def traversal_path
        TraversalPathCalculator.new(path_a, path_b).path
      end

      class TraversalPathCalculator < Struct.new(:path_a, :path_b)
        def path
          result = [path_a]
          return [path_a, path_b] if path_a.dirname == path_b.dirname

          traversal = path_b.relative_path_from(path_a)
          current_path = path_a

          traversal.descend do |p|
            current_path = full(path_a, p)
            result.push(current_path)
          end

          remove_superfluous_traversals(result)
        end

        def full(start, traversal)
          start.realpath + Pathname.new(traversal)
        end

        def remove_superfluous_traversals(input)
          SuperfluousRemoval.new(input).trim
        end

        class SuperfluousRemoval < Array
          def initialize(traversals)
            super()
            @in_parent = false
            @traversals = traversals
          end

          def trim
            @traversals.each { |i| process(i) }
            self
          end

          def process(i)
            if @in_parent
              @in_parent = false
              remove_parent(i)
            else
              add_item(i)
            end
          end

          private

          def add_item(i)
            @in_parent = ((last && last + "..") == i)
            push i
          end

          def remove_parent(i)
            remove_dir(i) if same_dir?(i)
          end

          def same_dir?(i)
            self[-2] && self[-2].dirname == i.dirname
          end

          def remove_dir(i)
            pop
            push i
          end
        end
      end
    end
  end
end
