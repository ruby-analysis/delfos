# frozen_string_literal: true

module Delfos
  module FileSystem
    class Relation
      attr_reader :start_path, :finish_path

      def initialize(start_path, finish_path)
        @start_path = start_path
        @finish_path = finish_path
      end

      def other_files
        RelatedPaths.new(start_path).files
      end

      def other_directories
        RelatedPaths.new(start_path).directories
      end

      def distance
        return traversed_files.length       if both_files?
        return traversed_directories.length if both_directories?

        traversed_files.length + traversed_directories.length
      end

      def possible_length
        other_files.length + other_directories.length
      end

      def traversed_files
        start_at_end = (start_path.file? && finish_path.directory?)

        subset_to_traverse(collection: other_files,
                           start: start_path,
                           finish: finish_path,
                           start_at_end: start_at_end)
      end

      def traversed_directories
        start_at_end = (start_path.file? && finish_path.directory?) || (start_path.directory? && finish_path.file?)

        subset_to_traverse(collection: other_directories,
                           start: start_path,
                           finish: finish_path,
                           start_at_end: start_at_end)
      end

      def subset_to_traverse(collection:, start:, finish:, start_at_end: true)
        start_index, finish_index = indexes_from(collection, start, finish, start_at_end)

        Array collection[start_index..finish_index]
      end

      private

      def both_files?
        start_path.file? && finish_path.file?
      end

      def both_directories?
        start_path.directory? && finish_path.directory?
      end

      def indexes_from(collection, start, finish, start_at_end)
        start_index  = index_from(collection, start,  start_at_end: start_at_end)
        finish_index = index_from(collection, finish, start_at_end: start_at_end, reverse: true)

        if start_index.zero? && finish_index.zero?
          finish_index = collection.length - 1
        end

        [start_index, finish_index].sort
      end

      def index_from(collection, value, reverse: false, start_at_end: false)
        index = collection.index value

        if index.nil?
          index = start_at_end && !reverse ? collection.length - 1 : 0
        end

        index
      end

      class RelatedPaths
        attr_reader :path

        def initialize(path)
          @path = path
        end

        def files
          all.select(&:file?)
        end

        def directories
          all.select(&:directory?)
        end

        private

        def all
          Dir.glob(path.dirname + "*").map { |f| Pathname.new(f) }
        end
      end
    end

    class ChildFile < Relation
      def other_files
        RelatedPaths.new(start_path + "*").files
      end

      def other_directories
        RelatedPaths.new(start_path + "*").directories
      end
    end
  end
end
