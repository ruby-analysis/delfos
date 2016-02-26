require "pathname"
require_relative "common_path"

module Delfos
  class << self
    attr_accessor :logger
  end

        REPO_PATH = "/Users/MarkB/code/notonthehighstreet/"
  module MethodLogging
    class << self
      def log(called_object,
              _, args, keyword_args, block,
              class_method, stack, caller_binding,
              called_method)
        calling_object, calling_method, calling_file, calling_line_number = fetch_details_from_caller(stack, caller_binding)

        args = args.map(&:class)
        symbol = class_method ? "." : "#"
        keyword_args = keyword_args.dup
        keyword_args.each do |k,v|
          keyword_args[k]= v.class
        end

        called_klass = if called_object.is_a?(Class)
          called_object
        else
          called_object.class
        end

        calling_klass = if calling_object.is_a?(Class)
          calling_object
        else
          calling_object.class
        end


        called_file, called_line_number = called_method.source_location

        calling_file = calling_file.gsub REPO_PATH, "" if calling_file
        called_file = called_file.gsub REPO_PATH, "" if called_file

        Delfos.logger.debug(
          class_method, args, keyword_args,
          calling_klass, calling_file, calling_line_number, calling_method,
          called_klass,  called_file,  called_line_number,  called_method.name
        )
      end

      def exclude_from_logging?(method)
        file, line_number = method.source_location
        return true unless file

        exclude_file_from_logging?(file)
      end

      def include_file_in_logging?(file)
        !exclude_file_from_logging?(file)
      end

      def exclude_file_from_logging?(file)
        path = Pathname.new(file)

        logging_directories.all? do |logging_root|
          common_path = Delfos::CommonPath.common_parent_directory_path(path, logging_root)

          common_path.to_s.length < logging_root.to_s.length
        end
      end

      def fetch_details_from_caller(stack, caller_binding)
        current_caller = stack.detect{|f| include_file_in_logging?(f) }

        return unless current_caller

        stack_index = stack.index{|c| c == current_caller}

        caller_self = caller_binding.of_caller(stack_index + 3).eval('self')


        file, line_number, rest = current_caller.split(":")
        calling_method = rest[/`.*'$/]
        calling_method = calling_method.gsub("`", "").gsub("'", "") rescue nil

        [caller_self, calling_method, file, line_number]
      end


      def logging_directories=(directories)
        @logging_directories = directories
        #Don't monkey patch object until we have any directories defined
        require_relative "perform_patching"
      end

      attr_reader :logging_directories
    end
  end
end

