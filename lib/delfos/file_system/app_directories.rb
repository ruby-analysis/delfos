# frozen_string_literal: true

require_relative "common_path"
require_relative "file_cache"

module Delfos
  module FileSystem
    class AppDirectories
      include FileCache

      def initialize(included, excluded)
        @included, @excluded = included, excluded
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

      def matches(f, directories)
        CommonPath.included_in?(expand_path(f), directories)
      end

      def expand_path(f)
        Pathname.new(f).expand_path
      end
    end
  end
end
