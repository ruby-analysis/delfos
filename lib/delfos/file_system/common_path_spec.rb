# frozen_string_literal: true
require_relative "common_path"
require "delfos/file_system/pathname"

module Delfos
  module FileSystem
    describe CommonPath do
      def pathname(path_string, directory:)
        path = double "path: #{path_string}", to_s: path_string, directory?: directory

        allow(path).to receive(:+) do |other|
          path_string + other
        end

        allow(path).to receive(:expand_path) do
          ::Pathname.new(path_string).expand_path
        end

        path
      end

      before do
        allow(Pathname).to receive(:new) do |path|
          directory = (path.to_s[-1] == "/") || !path.to_s[/\.rb$/]
          pathname(path, directory: directory)
        end
      end

      describe "#included_in?" do
        it "determines the common paths" do
          result = described_class.included_in?("/a/b/c/d", ["/a/b/c/d/e", "/b"])
          expect(result).to be_falsey
        end

        it "works with a directory without trailing slash" do
          path = ::Pathname.new(".").expand_path "./fixtures/a.rb"
          fixtures_path = ::Pathname.new(".").expand_path "./fixtures"
          result = described_class.included_in?(path, [fixtures_path])
          expect(result).to be_truthy
        end

        it "works with a single path" do
          result = described_class.included_in?("/a/b/c/d", ["/q"])
          expect(result).to be_falsey
        end

        it "works with a trailing slash" do
          result = described_class.included_in?("/a/b/c/d", ["/a/b/c/d/"])
          expect(result).to be_truthy

          result = described_class.included_in?("/a/b/c/d/", ["/a/b/c/d"])
          expect(result).to be_truthy
        end

        it "works with a single path" do
          result = described_class.included_in?("/a/b/c/d", ["/a"])
          expect(result).to be_truthy
        end

        it "works with a file" do
          result = described_class.included_in?("/b/c/d.rb", ["/a/b", "/b"])
          expect(result).to be_truthy
        end

        it "determines the common paths" do
          result = described_class.included_in?("/b/c/d", ["/a/b", "/b"])
          expect(result).to be_truthy
        end
      end

      it "determines the common path" do
        # common is LHS value
        result = described_class.send(:common_parent, "/a/b/c/d", "/a/b/c/d/e")
        expect(result.to_s).to eq "/a/b/c/d/"

        # common is RHS value
        result = described_class.send(:common_parent, "/a/b/c", "/a/b")
        expect(result.to_s).to eq "/a/b/"

        # common is neither LHS nor RHS
        result = described_class.send(:common_parent, "/a/b/c/d", "/a/b/e/f")
        expect(result.to_s).to eq "/a/b/"

        # both paths same
        result = described_class.send(:common_parent, "/a/b", "/a/b")
        expect(result.to_s).to eq "/a/b/"
      end

      it "handles files" do
        result = described_class.send(:common_parent, "/a/b", "/a/b/c.rb")
        expect(result.to_s).to eq "/a/b/"

        result = described_class.send(:common_parent, "/a/b/c.rb", "/a/b/")
        expect(result.to_s).to eq "/a/b/"
      end

      it "handles the root path case" do
        result = described_class.send(:common_parent, "/a/b/c/d", "/e/f")
        expect(result.to_s).to eq "/"
      end
    end
  end
end
