# frozen_string_literal: true

require_relative "neo4j"

module Delfos
  RSpec.describe Neo4j do
    describe ".import_offline_queries" do
      let(:filename) { "some filename" }
      let(:importer) { double "Importer" }

      it do
        expect(importer).to receive(:perform)

        expect(described_class::Offline::Importer).
          to receive(:new).
          with(filename).
          and_return(importer)

        described_class.import_offline_queries(filename)
      end
    end
  end
end
