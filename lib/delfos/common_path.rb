# frozen_string_literal: true
require "pathname"

module Delfos
  module CommonPath
    def self.included_in?(p1, paths)
      paths.map do |p2|
        common = common_parent_directory_path(p1, p2)
        common.to_s.length >= p2.to_s.length
      end.
        compact.
        detect { |v| v }
    end

    def self.common_parent_directory_path(path_a, path_b)
      separator = "/"
      dirs = [path_a.to_s, path_b.to_s]

      dir1, dir2 = dirs.minmax.map { |dir| dir.split(separator) }

      common_path = dir1.
                    zip(dir2).
                    take_while { |dn1, dn2| dn1 == dn2 }.
                    map(&:first).
                    join(separator)

      common_path = "/" if common_path == ""

      if (common_path.to_s.length <= path_a.to_s.length) ||
         (common_path.to_s.length <= path_b.to_s.length)
        Pathname.new(common_path)
      end
    end
  end
end
