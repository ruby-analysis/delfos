# frozen_string_literal: true

require_relative "common_path"
require_relative "file_cache"

module Delfos
  module FileSystem
    class AppDirectories
      include FileCache

      def initialize(included, excluded)
        @included = included
        @excluded = excluded
      end

      def exclude?(file)
        !include?(file)
      end

      def include?(file)
        return false if file.nil?
        with_cache(file) { should_include?(file) }
      end

      private

      def should_include?(file)
        !matches(file, @excluded) && matches(file, @included)
      end

      def matches(file, directories)
        CommonPath.included_in?(expand_path(file), directories)
      end

      def expand_path(file)
        Pathname.new(file).expand_path
      end
    end
  end
end
