# frozen_string_literal: true

require_relative "file_cache"

module Delfos
  module FileSystem
    class AppFiles
      include FileCache

      def initialize(included, excluded)
        @included, @excluded = included, excluded
      end

      def include?(file)
        !exclude?(file)
      end

      def exclude?(file)
        return false if file.nil?
        with_cache(file) { should_exclude?(file) }
      end

      private

      def should_exclude?(file)
        @excluded.include?(Pathname(file).expand_path)
      end
    end
  end
end
