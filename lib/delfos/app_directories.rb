# frozen_string_literal: true
require "delfos/file_system/common_path"
require "delfos/file_system/pathname"

module Delfos
  module AppDirectories
    extend self

    def exclude_file?(file)
      !include_file?(file)
    end

    def include_files?(*files)
      files.all?{|f| include_file?(f) }
    end

    def include_file?(file)
      return false if file.nil?
      with_cache(file) { should_include?(file) }
    end

    def reset!
      @cache = nil
    end

    private

    def should_include?(file)
      FileSystem::CommonPath.included_in?(expand_path(file), Delfos.application_directories)
    end

    def expand_path(f)
      Pathname.new(f).expand_path
    end

    def with_cache(key)
      cache.include?(key) ? cache[key] : cache[key] = yield
    end

    def cache
      @cache ||= {}
    end
  end
end
