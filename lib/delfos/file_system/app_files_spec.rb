# frozen_string_literal: true

require_relative "app_files"

module Delfos
  module FileSystem
    RSpec.describe AppFiles do
      let(:a_path) { Pathname(File.expand_path("./fixtures/a.rb")) }
      let(:b_path) { Pathname(File.expand_path("./fixtures/b.rb")) }

      subject do
        described_class.new(included_files, excluded_files)
      end

      let(:excluded_files) { [ a_path ] }
      let(:included_files) { [] }

      describe "#include?" do
        context "with a file to exclude" do
          let(:file) { a_path }

          it do
            expect(subject.include?(file)).to eq false
          end
        end

        context "with a file include" do
          let(:file) { b_path }

          it do
            expect(subject.include?(file)).to eq true
          end
        end
      end
    end
  end
end
