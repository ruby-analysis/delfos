# frozen_string_literal: true

require "spec_helper"
require_relative "retryable"

module Delfos
  module Neo4j
    module QueryExecution
      module Batch
        RSpec.describe Retryable, "integration" do
          before do
            Delfos.setup_neo4j!
            WebMock.disable_net_connect! allow_localhost: true
          end

          describe ".execute!" do
            context "with 3 queries and a batch size of 3" do
              let(:params) { {} }
              let(:query) { "MERGE (n:Node{name:{name}}) - [r:RELATIONSHIP] -> (o:Other)" }
              let(:size) { 3 }
              let(:node_names) { ["some name", "another name", "a final name"] }
              let(:result) { perform_query("MATCH (n:Node) RETURN n.name") }

              context "success" do
                before do
                  node_names.each do |n|
                    described_class.execute!(query, params: { name: n }, size: size)
                  end
                end

                it do
                  expect(result.flatten.sort).to eq ["some name", "another name", "a final name"].sort
                end
              end

              context "with an expired transaction" do
                let(:errors) { [{ code: "some code", message: "some error message" }] }

                before do
                  require "logger"
                  @level = Delfos.logger.level
                  Delfos.logger.level = Logger::FATAL
                  call_count = 0

                  allow_any_instance_of(QueryExecution::Transactional).to receive(:perform).and_wrap_original do |m|
                    call_count += 1

                    if call_count <= 4
                      raise QueryExecution::ExpiredTransaction.new("some commit url".inspect, "")
                    end

                    m.()
                  end
                end

                after do
                  Delfos.logger.level = @level
                end

                it "retries the batch" do
                  node_names.each do |n|
                    described_class.execute!(query, params: { name: n }, size: size)
                  end

                  expect(result.flatten.sort).to eq ["some name", "another name", "a final name"].sort
                end
              end
            end
          end
        end
      end
    end
  end
end
