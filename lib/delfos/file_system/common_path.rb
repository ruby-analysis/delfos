# frozen_string_literal: true
module Delfos
  module FileSystem
    module CommonPath
      class << self
        SEPARATOR = "/"

        def included_in?(p1, paths)
          paths.any? do |p2|
            common = common_parent(p1, p2)
            common.to_s.length >= p2.to_s.length
          end
        end

        def common_parent(path_a, path_b)
          dirs = [
            Pathname.new(path_a.to_s).expand_path,
            Pathname.new(path_b.to_s).expand_path,
          ]

          dir1, dir2 = dirs.sort.map { |dir| dir.to_s.split(SEPARATOR) }
          append_trailing_slash!(path_from(dir1, dir2, path_a, path_b).to_s)
        end

        private

        def path_from(dir1, dir2, path_a, path_b)
          common_path = common_path(dir1, dir2)
          common_path, path_a, path_b = append_trailing_slashes!(common_path, path_a, path_b)

          Pathname.new(common_path) if valid_length?(common_path, path_a, path_b)
        end

        def valid_length?(common_path, path_a, path_b)
          l = common_path.to_s.length
          (l <= path_a.to_s.length) || (l <= path_b.to_s.length)
        end

        def common_path(dir1, dir2)
          dir1.
            zip(dir2).
            take_while { |dn1, dn2| dn1 == dn2 }.
            map(&:first).
            join(SEPARATOR)
        end

        def append_trailing_slash!(path)
          path = path.to_s

          if Pathname.new(path).directory?
            path += SEPARATOR if path && path.to_s[-1] != SEPARATOR
          end

          path
        end

        def append_trailing_slashes!(*paths)
          paths.map do |path|
            append_trailing_slash!(path)
          end
        end
      end
    end
  end
end
