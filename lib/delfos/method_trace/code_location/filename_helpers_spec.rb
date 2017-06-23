# frozen_string_literal: true

require "pathname"
require_relative "filename_helpers"

module Delfos
  module MethodTrace
    module CodeLocation
      RSpec.describe FilenameHelpers do
        describe "#file" do
          class SomeClass
            include FilenameHelpers

            def initialize(file)
              @file = file
            end
          end

          before do
            allow(Delfos).
              to receive(:application_directories).
              and_return [
                Pathname.new("./fixtures"),
                Pathname.new("./another_directory"),
              ]
          end

          subject { SomeClass.new(file) }

          context "with a top level file" do
            let(:file) { "fixtures/a.rb" }

            it do
              expect(subject.file).to eq "fixtures/a.rb"
              expect(subject.path).to eq "fixtures/a.rb"
              expect(subject.raw_path).to eq "fixtures/a.rb"
            end
          end

          context "with a full path" do
            context "with a top level file" do
              let(:file) { File.expand_path("./fixtures/a.rb") }

              it do
                expect(subject.file).to eq "fixtures/a.rb"
                expect(subject.path).to eq "fixtures/a.rb"
                expect(subject.raw_path).to eq file
              end
            end

            context "with a sub directory level file" do
              let(:file) { File.expand_path "fixtures/sub_directory/a.rb" }

              it do
                expect(subject.file).to eq "fixtures/sub_directory/a.rb"
                expect(subject.path).to eq "fixtures/sub_directory/a.rb"
                expect(subject.raw_path).to eq file
              end
            end

            context "with another sub directory level file" do
              let(:file) { File.expand_path "another_directory/a.rb" }

              it do
                expect(subject.file).to eq "another_directory/a.rb"
                expect(subject.path).to eq "another_directory/a.rb"
                expect(subject.raw_path).to eq File.expand_path "another_directory/a.rb"
              end
            end
          end

          context "with a non included file" do
            let(:file) { "/somewhere_else/another/a.rb" }

            it do
              expect(subject.file).to eq "/somewhere_else/another/a.rb"
              expect(subject.path).to eq "/somewhere_else/another/a.rb"
              expect(subject.raw_path).to eq "/somewhere_else/another/a.rb"
            end
          end

          context "with a sub directory level file" do
            let(:file) { "fixtures/sub_directory/a.rb" }

            it do
              expect(subject.file).to eq "fixtures/sub_directory/a.rb"
              expect(subject.path).to eq "fixtures/sub_directory/a.rb"
              expect(subject.raw_path).to eq "fixtures/sub_directory/a.rb"
            end
          end

          context "with another sub directory level file" do
            let(:file) { "another_directory/a.rb" }

            it do
              expect(subject.file).to eq "another_directory/a.rb"
              expect(subject.path).to eq "another_directory/a.rb"
              expect(subject.raw_path).to eq "another_directory/a.rb"
            end
          end
        end
      end
    end
  end
end
