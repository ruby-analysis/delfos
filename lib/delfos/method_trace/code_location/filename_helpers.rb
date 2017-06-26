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

          Delfos.config.included_directories.map do |d|
            file = relative_path(file, d)
          end

          file
        end

        def relative_path(file, dir)
          dir = File.expand_path(dir)
          match = dir.to_s.split("/")[0..-2].join("/")

          if match.length.positive? && file[match]
            file = file.gsub(match, "").
                   gsub(%r{^/}, "")
          end

          file
        end
      end
    end
  end
end
