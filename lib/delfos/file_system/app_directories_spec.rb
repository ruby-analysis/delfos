# frozen_string_literal: true

require_relative "app_directories"

module Delfos
  module FileSystem
    RSpec.describe AppDirectories do
      let(:call_site_logger) { double "call_site_logger", log: nil }

      let(:a_path) { File.expand_path "./fixtures/a.rb" }
      let(:b_path) { File.expand_path "./fixtures/b.rb" }
      let(:method_a) { double "method a", source_location: [a_path, 4] }
      let(:method_b) { double "method b", source_location: [b_path, 2] }

      let(:path_fixtures) { Pathname.new(File.expand_path("fixtures")) }
      let(:path_spec) { Pathname.new(File.expand_path(__FILE__)) + "../.." }

      subject do
        described_class.new([path_fixtures, path_spec], [])
      end

      describe "#exclude?" do
        context "with a file to include" do
          let(:file) { a_path }

          it do
            expect(subject.exclude?(file)).to eq false

            # reads from cache
            expect(subject).not_to receive(:should_include?)
            expect(subject.exclude?(file)).to eq false
          end
        end

        context "with a file to exclude" do
          let(:file) { "/etc/hosts" }

          it do
            expect(subject.exclude?(file)).to eq true
            # reads from cache
            expect(subject).not_to receive(:should_include?)
            expect(subject.exclude?(file)).to eq true
          end
        end
      end
    end
  end
end
