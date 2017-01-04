require "fiddle/import"

module Delfos
  module FileSystem
    module FileShim
      extend Fiddle::Importer

      dlload Fiddle.dlopen(nil)

      extern "void* path_expand_path(int argc, void *argv, void* self);"

      def self.expand_path(file, dir=nil)
        result = path_expand_path(2, [file, dir], self)
	result.to_value
      end
    end
  end
end

puts __FILE__
Delfos::FileSystem::FileShim.expand_path __FILE__, __FILE__
puts "here"
