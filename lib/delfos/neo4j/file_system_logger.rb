# frozen_string_literal: true

module Delfos
  module Neo4j
    class FileSystemLogger
      def initialize(output_path: nil)
        @output_path = output_path
        @count = 0
      end

      def execute(query, params)
        file.puts query.gsub("\n", "\\n")
        file.puts params.to_s.gsub("\n", "\\n")
        file.puts "\n\n----"
        @count += 1
        file.flush if @count % 100 == 0
      end

      def finish!
        file.flush
        file.close
      end

      private

      def file
        @file ||= File.open(@output_path, "a")
      end
    end
  end
end
