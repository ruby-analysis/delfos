# frozen_string_literal: true

require_relative "app_files"

module Delfos
  module FileSystem
    RSpec.describe AppFiles do
      let(:a_path) { Pathname(File.expand_path("./fixtures/a.rb")) }
      let(:b_path) { Pathname(File.expand_path("./fixtures/b.rb")) }

      before do
        described_class.reset!

        path_fixtures = Pathname.new(File.expand_path(__FILE__)) + "../../../../fixtures"
        path_spec     = Pathname.new(File.expand_path(__FILE__)) + "../.."

        Delfos.application_directories = [path_spec, path_fixtures]
        Delfos.ignored_files = [a_path]
      end

      describe "#include_file?" do
        context "with a file to exclude" do
          let(:file) { a_path }

          it do
            expect(described_class.include_file?(file)).to eq false
          end
        end

        context "with a file include" do
          let(:file) { b_path }

          it do
            expect(described_class.include_file?(file)).to eq true
          end
        end
      end
    end
  end
end
