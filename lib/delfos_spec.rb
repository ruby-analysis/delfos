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

    it do
      Delfos.setup!(application_directories: [directory])

      expect(Delfos.application_directories).to eq [Pathname.new(File.expand_path(directory))]
    end
  end

  describe "offline_query_saving=" do
    before do
      allow(Delfos::MethodTrace).to receive(:trace!)
      allow(Delfos).to receive(:call_site_logger).and_return double("call site logger")

      Delfos.setup!(offline_query_saving: offline_query_saving)
    end

    after do
      Delfos::Setup.reset_top_level_variables!
    end

    context "with a boolean true" do
      let(:offline_query_saving) { true }

      it "has a default filename" do
        expect(Delfos.offline_query_saving).to eq true
        expect(Delfos.offline_query_filename).to eq "delfos_query_parameters.json"
      end
    end

    context "with a boolean false" do
      let(:offline_query_saving) { false }

      it do
        expect(Delfos.offline_query_saving).to eq nil
        expect(Delfos.offline_query_filename).to eq nil
      end
    end

    context "with a string argument" do
      let(:offline_query_saving) { "some/path/some_file.cypher" }
      it do
        expect(Delfos.offline_query_saving).to eq "some/path/some_file.cypher"
        expect(Delfos.offline_query_filename).to eq "some/path/some_file.cypher"
      end
    end
  end
end
