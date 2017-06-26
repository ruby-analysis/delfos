# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require_relative "delfos"

RSpec.describe Delfos do
  describe "#include=" do
    let(:directory) { "fixtures" }

    it do
      Delfos.configure { |c| c.include = directory }
      expect(Delfos.config.included_directories).to eq [expand(directory)]
    end

    it do
      Delfos.configure { |c| c.include directory }
      expect(Delfos.config.included_directories).to include expand(directory)
    end
  end

  describe "excluded_files" do
    let(:ignored_file) { "fixtures/a.rb" }

    it do
      Delfos.configure { |c| c.exclude = ignored_file }
      expect(Delfos.config.excluded_files).to eq [expand(ignored_file)]
    end
  end

  def expand(file)
    Pathname.new(File.expand_path(file))
  end

  describe "#include_file?" do
    let(:application_directories) { "fixtures" }
    let(:ignored_file) { "fixtures/a.rb" }
    let(:included_file) { "fixtures/b.rb" }

    before do
      Delfos.configure do |c|
        c.include = application_directories
        c.exclude ignored_file
      end
      Delfos.start!
    end

    after { Delfos.finish! }

    it "includes the correct file" do
      expect(Delfos.include_file?(included_file)).to be true
    end

    it "excludes the correct file" do
      expect(Delfos.include_file?(ignored_file)).to be false
    end
  end

  describe "offline_query_saving=" do
    before do
      allow(Delfos::MethodTrace).to receive(:trace!)
      allow(Delfos).to receive(:call_site_logger).and_return double("call site logger")

      Delfos.configure do |c|
        c.offline_query_saving = offline_query_saving
        c.offline_query_filename = offline_query_filename
      end
    end

    after do
      begin
      Delfos.finish!
      rescue Errno::ENOENT
      end
    end

    context "with a boolean true" do
      let(:offline_query_saving) { true }
      let(:offline_query_filename) { nil }

      it "has a default filename" do
        expect(Delfos.offline_query_saving).to eq true
        expect(Delfos.offline_query_filename).to eq "./tmp/delfos_query_parameters.json"
      end
    end

    context "with a boolean false" do
      let(:offline_query_saving) { false }
      let(:offline_query_filename) { nil }

      it do
        expect(Delfos.offline_query_saving).to eq false
        expect(Delfos.offline_query_filename).to eq nil
      end
    end

    context "with a path" do
      let(:offline_query_saving) { true }
      let(:offline_query_filename) { "some/path/some_file.cypher" }
      it do
        expect(Delfos.offline_query_saving).to eq true
        expect(Delfos.offline_query_filename).to eq "some/path/some_file.cypher"
      end
    end
  end
end
