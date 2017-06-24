# frozen_string_literal: true

require_relative "common_path"
require_relative "file_cache"

module Delfos
  module FileSystem
    module AppDirectories
      include FileCache
      extend self

      def exclude_file?(file)
        !include_file?(file)
      end

      def include_file?(file)
        return false if file.nil?
        with_cache(file) { should_include?(file) }
      end

      private

      def should_include?(file)
        CommonPath.included_in?(expand_path(file), Delfos.application_directories)
      end

      def expand_path(f)
        Pathname.new(f).expand_path
      end
    end
  end
end
