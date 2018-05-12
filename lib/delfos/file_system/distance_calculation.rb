# frozen_string_literal: true

require_relative "relation"
require_relative "path_determination"

module Delfos
  module FileSystem
    Error = Class.new(::StandardError)

    class DistanceCalculation
      attr_reader :path_a, :path_b

      PathNotFound = Class.new(Error)

      def initialize(path_a, path_b)
        @path_a, @path_b = PathDetermination.for(path_a, path_b)

        return if @path_a && @path_b

        raise PathNotFound, "path_a: #{path_a} -> #{@path_a.inspect}, path_b: #{path_b} -> #{@path_b.inspect}"
      end

      attr_reader :traversal_a, :traversal_b

      def traversals
        result = []
        path = traversal_path

        path.each_cons(2) do |start, finish|
          klass = klass_for(start, finish)
          result.push(klass.new(start, finish))
        end

        result
      end

      def klass_for(start, finish)
        return ChildFile if finish + ".." == start
        Relation
      end

      def sum_traversals
        traversals.sum(&:distance)
      end

      def sum_possible_traversals
        traversals.sum(&:possible_length)
      end

      def sibling_directories(path)
        siblings(path).select { |f| Pathname.new(f).directory?(f) }
      end

      def traversal_path
        TraversalPathCalculator.new(path_a, path_b).path
      end

      class TraversalPathCalculator
        attr_reader :path_a, :path_b

        def initialize(path_a, path_b)
          @path_a = path_a
          @path_b = path_b
        end

        def path
          return [path_a, path_b] if same_directory?

          current_path = path_a

          traversal.descend do |p|
            current_path = full(path_a, p)
            result.process(current_path)
          end

          result
        end

        def same_directory?
          path_a.dirname == path_b.dirname
        end

        def result
          @result ||= Result.new([path_a])
        end

        def traversal
          path_b.relative_path_from(path_a)
        end

        def full(start, traversal)
          start.realpath + Pathname.new(traversal)
        end

        class Result < Array
          def initialize(*args)
            super
            @in_parent = false
          end

          def process(path)
            if @in_parent
              @in_parent = false
              remove_parent(path)
            else
              add_item(path)
            end
          end

          private

          def add_item(path)
            @in_parent = ((last && last + "..") == path)
            push path
          end

          def remove_parent(path)
            return unless same_dir?(path)

            pop
            push(path)
          end

          def same_dir?(path)
            self[-2] && self[-2].dirname == path.dirname
          end
        end
      end
    end
  end
end
