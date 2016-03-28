# frozen_string_literal: true
require "pathname"

module Delfos
  module CommonPath
    class << self
      SEPARATOR = "/"

      def included_in?(p1, paths)
        paths = paths.map do |p2|
          common = common_parent_directory_path(p1, p2)
          common.to_s.length >= p2.to_s.length
        end

        paths.compact.detect { |v| v }
      end

      def common_parent_directory_path(path_a, path_b)
        dirs = [File.expand_path(path_a.to_s), File.expand_path(path_b.to_s)]

        dir1, dir2 = dirs.minmax.map { |dir| dir.split(SEPARATOR) }

        path_from(dir1, dir2, path_a, path_b)
      end

      private

      def path_from(dir1, dir2, path_a, path_b)
        common_path = common_path(dir1, dir2)
        common_path, path_a, path_b = append_trailing_slashes!(common_path, path_a, path_b)

        if valid_length?(common_path, path_a, path_b)
          Pathname.new(common_path)
        end
      end

      def valid_length?(common_path, path_a, path_b)
        (common_path.to_s.length <= path_a.to_s.length) || (common_path.to_s.length <= path_b.to_s.length)
      end

      def common_path(dir1, dir2)
        dir1.
          zip(dir2).
          take_while { |dn1, dn2| dn1 == dn2 }.
          map(&:first).
          join(SEPARATOR)
      end

      def append_trailing_slashes!(*paths)
        paths.map do |path|
          if Pathname.new(path).directory?
            path += SEPARATOR if path && path.to_s[-1] != SEPARATOR
          end

          path
        end
      end
    end
  end
end
