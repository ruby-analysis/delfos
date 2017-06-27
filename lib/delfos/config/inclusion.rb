# frozen_string_literal: true

require "delfos/file_system/app_directories"
require "delfos/file_system/app_files"

module Delfos
  class Config
    class Inclusion
      attr_reader :included_directories, :included_files,
        :excluded_directories, :excluded_files

      def initialize
        require "pathname"
        @included_directories = default_included_directories
        @included_files = []

        @excluded_directories = []
        @excluded_files = []
      end

      def exclude(paths)
        append_all_to(paths, "excluded")
      end

      def include(paths)
        append_all_to(paths, "included")
      end

      def include=(paths)
        replace_all_with(paths, "included")
      end

      def exclude=(paths)
        replace_all_with(paths, "excluded")
      end

      def include?(file)
        app_directories.include?(file) && app_files.include?(file)
      end

      private

      def append_all_to(paths, type)
        files, directories = files_and_directories_from(paths)

        append_to(files, "@#{type}_files")
        append_to(directories, "@#{type}_directories")
      end

      def append_to(paths, ivar_name)
        ivar = instance_variable_get(ivar_name)
        ivar += paths
        ivar.uniq!
        instance_variable_set(ivar_name, ivar)
      end

      def replace_all_with(paths, type)
        files, directories = files_and_directories_from(paths)

        replace_with(files, "@#{type}_files")
        replace_with(directories, "@#{type}_directories")
      end

      def replace_with(paths, ivar_name)
        instance_variable_set(ivar_name, paths)
        instance_variable_get(ivar_name).uniq!
      end

      def files_and_directories_from(paths)
        expand_paths(paths).partition(&:file?)
      end

      def app_directories
        @app_directories ||= FileSystem.app_directories(@included_directories, @excluded_directories)
      end

      def app_files
        @app_files ||= FileSystem.app_files(@included_files, @excluded_files)
      end

      def default_included_directories
        %w[app lib].map { |f| Pathname.new(f.to_s).expand_path }
      end

      def expand_paths(files)
        Array(files).compact.map { |f| Pathname.new(f.to_s).expand_path }
      end
    end
  end
end
