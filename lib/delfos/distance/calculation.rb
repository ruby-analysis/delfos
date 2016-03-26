# frozen_string_literal: true
require_relative "relation"

module Delfos
  module Distance
    class Calculation
      attr_reader :path_a, :path_b

      def initialize(path_a, path_b)
        @path_a = path_a
        @path_b = path_b
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

      def klass_for(a, b)
        return ChildFile if b + ".." == a
        Relation
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
          return [path_a, path_b] if path_a.dirname == path_b.dirname

          current_path = path_a

          traversal.descend do |p|
            current_path = full(path_a, p)
            result.process(current_path)
          end

          result
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
            return unless same_dir?(i)

            pop
            push(i)
          end

          def same_dir?(i)
            self[-2] && self[-2].dirname == i.dirname
          end
        end
      end
    end
  end
end
