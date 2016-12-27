# frozen_string_literal: true
require "delfos/file_system/common_path"

require_relative "method_logging/code_location"
require_relative "method_logging/method_parameters"

module Delfos
  module MethodLogging
    extend self
    def log(call_site, called_object, called_method, class_method, parameters)
      called_code = CodeLocation.from_called(called_object, called_method, class_method)

      Delfos.call_site_logger.log(parameters, call_site, called_code)
    end

    def exclude?(method)
      file, = method.source_location
      return true unless file

      exclude_file?(File.expand_path(file))
    end

    def include_file?(file)
      !exclude_file?(file)
    end

    def exclude_file?(file)
      with_cache(file) do
        !FileSystem::CommonPath.included_in?(File.expand_path(file), Delfos.application_directories)
      end
    end

    def reset!
      @cache = nil
    end

    private

    def with_cache(key)
      cache.include?(key) ? cache[key] : cache[key] = yield
    end

    def cache
      @cache ||= {}
    end
  end
end
