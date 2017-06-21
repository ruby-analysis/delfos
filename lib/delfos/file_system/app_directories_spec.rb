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

      before do
        described_class.reset!

        Delfos.call_site_logger = call_site_logger

        path_fixtures = Pathname.new(File.expand_path(__FILE__)) + "../../../../fixtures"
        path_spec     = Pathname.new(File.expand_path(__FILE__)) + "../.."

        Delfos.application_directories = [path_spec, path_fixtures]
      end

      describe ".exclude_file?" do
        context "with a file to include" do
          let(:file) { a_path }

          it do
            expect(described_class.exclude_file?(file)).to eq false

            # reads from cache
            expect(described_class).not_to receive(:should_include?)
            expect(described_class.exclude_file?(file)).to eq false
          end
        end

        context "with a file to exclude" do
          let(:file) { "/etc/hosts" }

          it do
            expect(described_class.exclude_file?(file)).to eq true

            # reads from cache
            expect(described_class).not_to receive(:should_include?)
            expect(described_class.exclude_file?(file)).to eq true
          end
        end
      end
    end
  end
end
