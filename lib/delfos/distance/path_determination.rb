module Delfos
  module Distance
    class PathDetermination
      def self.for(*files)
        files.map{|f| new(f).full_path }
      end

      def initialize(file)
        @file = Pathname.new(strip_block_message(file))
      end

      def full_path
        return @file.realpath if File.exist?(@file)

        Delfos.application_directories.map do |d|
          path = try_path{ d + @file }

          path || try_path do
            Pathname.new(d + @file.to_s.gsub(%r{[^/]*/}, ""))
          end
        end.compact.first
      end

      private

      def strip_block_message(f)
        f.to_s.split(" in block").first
      end

      def try_path
        path = yield
        path if path.exist?
      end
    end
  end
end
