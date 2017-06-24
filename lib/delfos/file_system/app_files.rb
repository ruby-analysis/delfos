# frozen_string_literal: true

require_relative "file_cache"

module Delfos
  module FileSystem
    module AppFiles
      include FileCache
      extend self

      def include_file?(file)
        !exclude_file?(file)
      end

      def exclude_file?(file)
        return false if file.nil?
        with_cache(file) { should_exclude?(file) }
      end

      private

      def should_exclude?(file)
        Delfos.ignored_files&.include?(Pathname(file).expand_path)
      end
    end
  end
end
