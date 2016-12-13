# frozen_string_literal: true
require "pathname"
require "forwardable" unless defined? Forwardable
require "binding_of_caller"
require_relative "common_path"
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
      def log(call_site, called_object, called_method, class_method, arguments)
        return if skip_meta_programming_defined_method?
        arguments = Args.new(arguments)
        called_code = CodeLocation.from_called(called_object, called_method, class_method)

        Delfos.logger.debug(arguments, call_site, called_code)
      end

      def exclude?(method)
        file, _ = method.source_location
        return true unless file

        exclude_file_from_logging?(File.expand_path(file))
      end

      def exclude_file_from_logging?(file)
        !CommonPath.included_in?(File.expand_path(file), Delfos.application_directories)
      end

      def include_file_in_logging?(file)
        !exclude_file_from_logging?(file)
      end

      private

      def skip_meta_programming_defined_method?
        i = caller.index do |l|
          l["delfos/patching/basic_object.rb"]
        end

        l[i + 1][/`define_method'\z/] if i
      end
    end
  end
end
