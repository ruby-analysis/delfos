# frozen_string_literal: true
require "delfos/file_system/common_path"
require "delfos/file_system/pathname"

require_relative "method_logging/code_location"

module Delfos
  module MethodLogging
    extend self

    def save_call_stack(call_sites, execution_number)
      Delfos.call_site_logger.save_call_stack(call_sites, execution_number)
    end

    def log(call_site, called_code)
      Delfos.call_site_logger.log(call_site, called_code)
    end

    def exclude?(method)
      file, = method.source_location
      return true unless file

      exclude_file?(expand_path(file))
    end

    def include_file?(file)
      !exclude_file?(file)
    end

    def exclude_file?(file)
      with_cache(file) do
        !FileSystem::CommonPath.included_in?(expand_path(file), Delfos.application_directories)
      end
    end

    def reset!
      @cache = nil
    end

    private

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
