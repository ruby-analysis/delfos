# frozen_string_literal: true

module Delfos
  module MethodTrace
    module CodeLocation
      module FilenameHelpers
        def path
          file
        end

        def file
          relative_filename(@file)
        end

        def raw_path
          @file
        end

        private

        def relative_filename(f)
          return unless f
          file = f.to_s

          Delfos.application_directories.map do |d|
            file = relative_path(file, d)
          end

          file
        end

        def relative_path(file, dir)
          match = dir.to_s.split("/")[0..-2].join("/")

          if file[match]
            file = file.gsub(match, "").
              gsub(%r{^/}, "")
          end

          file
        end
      end
    end
  end
end
