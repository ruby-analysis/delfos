# frozen_string_literal: true
require "pathname"
require "forwardable" unless defined? Forwardable
require "binding_of_caller"
require_relative "common_path"
require_relative "method_logging/klass_determination"
require_relative "method_logging/code_location"
require_relative "method_logging/args"
require_relative "execution_chain"

module Delfos
  class << self
    attr_accessor :logger, :application_directories
    attr_writer :method_logging

    def method_logging
      @method_logging ||= ::Delfos::MethodLogging
    end
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
        stack, call_site_binding,
        called_method)
        check_setup!

        call_site = CodeLocation.from_call_site(stack, call_site_binding)
        Delfos::ExecutionChain.push(call_site)

        return unless call_site

        args = Args.new(args.dup, keyword_args.dup)

        called_code = CodeLocation.from_called(called_object, called_method, class_method)

        Delfos.logger.debug(args, call_site, called_code)
      end

      def include_any_path_in_logging?(paths)
        Array(paths).inject(false) do |result, path|
          result || include_file_in_logging?(path)
        end
      end

      def exclude?(method)
        file, _line_number = method.source_location
        return true unless file

        exclude_file_from_logging?(File.expand_path(file))
      end

      def include_file_in_logging?(file)
        !exclude_file_from_logging?(file)
      end

      def exclude_file_from_logging?(file)
        check_setup!
        path = Pathname.new(File.expand_path file)

        if Delfos.application_directories.is_a? Proc
          Delfos.application_directories.call(path)
        else
          !CommonPath.included_in?(path, Delfos.application_directories)
        end
      end
    end
  end
end
