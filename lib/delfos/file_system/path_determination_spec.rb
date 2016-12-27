# frozen_string_literal: true
require_relative "path_determination"

module Delfos
  module Distance
    describe PathDetermination do
      before do
        Delfos.setup! application_directories: ["fixtures/path_determination"]
      end

      describe "#full_path" do
        let(:result) { described_class.new(search).full_path }

        context do
          let(:search) { "lib/example.rb" }

          it do
            expect(result.to_s).to eq File.expand_path("fixtures/path_determination/lib/example.rb").to_s
          end
        end

        context "with a fully specified path" do
          let(:search) { File.expand_path("fixtures/path_determination/lib/example.rb") }

          it do
            expect(result.to_s).to eq File.expand_path("fixtures/path_determination/lib/example.rb").to_s
          end
        end
      end
    end
  end
end
