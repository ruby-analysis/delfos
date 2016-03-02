require "pathname"
require "forwardable"
require "binding_of_caller"
require_relative "common_path"

module Delfos
  class << self
    attr_accessor :logger, :application_directories
  end

  class ApplicationDirectoriesNotDefined < StandardError
    def initialize *args
      super "Please set Delfos.application_directories"
    end
  end

  module MethodLogging
    class << self
      def log(called_object,
              _, args, keyword_args, block,
              class_method,
              stack, caller_binding,
              called_method)
        raise Delfos::ApplicationDirectoriesNotDefined unless Delfos.application_directories

        caller_code = Code.from(stack, caller_binding, class_method)
        return unless caller_code

        args = Args.new args.dup, keyword_args.dup

        called_code = Code.from_method(called_object, called_method, class_method)

        Delfos.logger.debug(args, caller_code, called_code)
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

        Delfos.application_directories.all? do |logging_root|
          common_path = Delfos::CommonPath.common_parent_directory_path(path, logging_root)

          common_path.to_s.length < logging_root.to_s.length
        end
      end
    end

    module KlassDetermination
      private

      def klass_for(object)
        if object.is_a?(Class)
          object
        else
          object.class
        end
      rescue Exception => e
        byebug
      end
    end

    class Code < Struct.new(:code_location)
      extend Forwardable
      delegate [:object, :method_type, :method_name, :line_number] => :code_location

      def self.from(stack, caller_binding, class_method)
        location = CodeLocation.from(stack, caller_binding, class_method)
        return unless location
        new location
      end

      def self.from_method(object, called_method, class_method)
        location = CodeLocation.from_method(object, called_method, class_method)
        return unless location
        new location
      end

      def file
        file = code_location.file.to_s

        if file
          Delfos.application_directories.map do |d|
            file = file.gsub(d.to_s.split("/")[0..-2].join("/"), "")
          end
        end

        file
      end

      def klass
        name = code_location.klass.name || "__AnonymousClass"
        name.gsub ":", "_"
      end
    end

    class CodeLocation < Struct.new(:object, :method_name, :method_type, :file, :line_number)
      include KlassDetermination

      def self.from(stack, caller_binding, class_method)
        current = stack.detect{|f| Delfos::MethodLogging.include_file_in_logging?(f) }

        return unless current

        stack_index = stack.index{|c| c == current}

        object = caller_binding.of_caller(stack_index + 3).eval('self')

        file, line_number, rest = current.split(":")
        method_name = rest[/`.*'$/]
        method_name = method_name.gsub("`", "").gsub("'", "") rescue nil

        new(object, method_name, class_method, file, line_number)
      end

      def self.from_method(object, called_method, class_method)
        file, line_number = called_method.source_location

        new(object, called_method.name, class_method, file, line_number)
      end

      def klass
        klass_for(object)
      end
    end


    class Args < Struct.new(:args, :keyword_args)
      include KlassDetermination

      def formatted_args
        args.map{|k| klass_for(k) }
      end

      def formatted_keyword_args
        keyword_args.values.map{|k| klass_for(k) }
      end
    end


  end
end

