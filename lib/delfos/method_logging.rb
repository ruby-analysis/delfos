# frozen_string_literal: true
require "pathname"
require "forwardable"
require "binding_of_caller"
require_relative "common_path"
require_relative "method_logging/klass_determination"
require_relative "method_logging/code"
require_relative "method_logging/args"

module Delfos
  class << self
    attr_accessor :logger, :application_directories
  end

  class ApplicationDirectoriesNotDefined < StandardError
    def initialize(*_args)
      super "Please set Delfos.application_directories"
    end
  end

  module MethodLogging
    class << self
      def check_setup!
        raise Delfos::ApplicationDirectoriesNotDefined unless Delfos.application_directories
      end

      def log(called_object,
        args, keyword_args, _block,
        class_method,
        stack, caller_binding,
        called_method)
        check_setup!

        caller_code = Code.from(stack, caller_binding, class_method)
        return unless caller_code

        args = Args.new(args.dup, keyword_args.dup)

        called_code = Code.from_method(called_object, called_method, class_method)

        Delfos.logger.debug(args, caller_code, called_code)
      end

      def include_any_path_in_logging?(paths)
        paths.inject(false) do |result, path|
          result || Delfos::MethodLogging.include_file_in_logging?(path)
        end
      end

      def exclude_from_logging?(method)
        file, _line_number = method.source_location
        return true unless file

        exclude_file_from_logging?(File.expand_path(file))
      end

      def include_file_in_logging?(file)
        !exclude_file_from_logging?(file)
      end

      def exclude_file_from_logging?(file)
        check_setup!
        path = Pathname.new(file)
        !CommonPath.included_in?(path, Delfos.application_directories)
      end
    end
  end
end
