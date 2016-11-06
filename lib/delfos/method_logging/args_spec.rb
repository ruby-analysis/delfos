# frozen_string_literal: true
require_relative "args"
require "./fixtures/b"
require "./fixtures/a"

describe Delfos::MethodLogging::Args do
  let(:a) { A.new }
  let(:b) { B.new }
  let(:c) { 1 }
  let(:d) { "" }
  let(:a_path) { File.expand_path "./fixtures/a.rb" }
  let(:b_path) { File.expand_path "./fixtures/b.rb" }

  let(:method_logging) do
    double("method_logging").tap do |m|
      allow(m).to receive(:include_any_path_in_logging?) do |paths|
        ([a_path, b_path] & Array(paths)).length > 0
      end
    end

  end

  before do
    definition = lambda do |k|
      case k.to_s
      when "A"
        [[a_path, 1], [a_path, 23]]
      when "B"
        [[b_path, 34]]
      else
        [["/some-unincluded-path/example.rb", 12]]
      end
    end
    allow(Delfos::MethodLogging::AddedMethods).
      to receive(:method_sources_for, &definition)


    allow(Delfos).to receive(:method_logging).and_return method_logging
    path = Pathname.new(File.expand_path(__FILE__)) + "../../../../fixtures"
    Delfos.application_directories = [path]
  end

  subject { described_class.new([a, b, c, d], c: c, d: d) }

  describe "#args" do
    it do
      expect(subject.args).to eq [A, B]
    end
  end

  describe "#keyword_args" do
    it "ignores non application defined classes" do
      expect(subject.keyword_args).to eq []
    end
  end
end
