require_relative "path_determination"

module Delfos
  module Neo4j
    module Distance
      describe PathDetermination do
        describe ".for" do
          before do
            Delfos.setup! application_directories: ["fixtures/ruby"]
          end

          it do
            result = described_class.new("/ruby/this.rb").full_path

            expect(result.to_s).to eq File.expand_path("fixtures/ruby/this.rb").to_s
          end
        end
      end
    end
  end
end

