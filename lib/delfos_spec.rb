# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require_relative "delfos"

RSpec.describe Delfos do
  before do
    Delfos::Setup.reset_top_level_variables!
  end

  describe "#application_directories=" do
    let(:directory) { "some/dir" }
    after { Delfos.disable! }

    it do
      Delfos.configure { |c| c.application_directories = directory }
      Delfos.start!
      expect(Delfos.application_directories).to eq [Pathname.new(File.expand_path(directory))]
    end
  end

  describe "ignored_files" do
    let(:ignored_file) { "app/some_file.rb" }

    it do
      Delfos.configure { |c| c.ignored_files = ignored_file }
      expect(Delfos.ignored_files).to eq [Pathname.new(File.expand_path(ignored_file))]
    end
  end

  describe "#include_file?" do
    let(:application_directories) { "fixtures" }
    let(:ignored_file) { "fixtures/a.rb" }
    let(:included_file) { "fixtures/b.rb" }

    before do
      Delfos.configure do |c|
        c.application_directories = application_directories
        c.ignored_files = ignored_file
      end
      Delfos.start!
    end

    after { Delfos.disable! }

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
      Delfos.disable!
    end

    context "with a boolean true" do
      let(:offline_query_saving) { true }
      let(:offline_query_filename) { nil }

      it "has a default filename" do
        expect(Delfos.offline_query_saving).to eq true
        expect(Delfos.offline_query_filename).to eq "delfos_query_parameters.json"
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
