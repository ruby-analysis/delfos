# frozen_string_literal: true

require "pathname"

module Delfos
  module FileSystem
    class PathDetermination
      def self.for(*files)
        files.map { |f| new(f).full_path }
      end

      def initialize(file)
        @file = Pathname.new(strip_block_message(file))
      end

      def full_path
        return @file.realpath if Pathname.new(@file).exist?
        Delfos.config.included_directories.map do |d|
          determine_path(d)
        end.compact.first
      end

      private

      def determine_path(directory)
        path = try_path { directory + @file }

        path || try_path do
          Pathname.new(directory + @file.to_s.gsub(%r{[^/]*/}, ""))
        end
      end

      def strip_block_message(file)
        file.to_s.split(" in block").first
      end

      def try_path
        path = yield
        path if path.exist?
      end
    end
  end
end
