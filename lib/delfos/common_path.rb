require "pathname"

module Delfos
  module CommonPath
    def self.common_parent_directory_path(path_a, path_b)
      separator = '/'
      dirs = [path_a.to_s, path_b.to_s]

      dir1, dir2 = dirs.minmax.map{|dir| dir.split(separator) }

      path = dir1.
        zip(dir2).
        take_while{|dn1,dn2| dn1 == dn2 }.
        map(&:first).
        join(separator)

      Pathname.new(path)
    end
  end
end
