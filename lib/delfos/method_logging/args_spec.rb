# frozen_string_literal: true
require_relative "args"
require "./fixtures/b"
require "./fixtures/a"

describe Delfos::MethodLogging::Args do
  let(:a) { A.new }
  let(:b) { B.new }
  let(:c) { 1 }
  let(:d) { "" }
  let(:args) { described_class.new([a, b, c, d], c: c, d: d) }
  let(:a_path) { File.expand_path "./fixtures/a.rb" }
  let(:b_path) { File.expand_path "./fixtures/b.rb" }

  before do
    allow(Delfos::Patching).
      to receive(:added_methods).
      and_return(added_methods)
  end

  let(:added_methods) do
    {
      "A" => { "instance_method_some_method"    =>  method_a},
      "B" => { "instance_method_another_method" =>  method_b},
    }
  end
  let(:method_a) { double "method a", source_location: [File.expand_path("fixtures/a.rb"), 4] }
  let(:method_b) { double "method b", source_location: [File.expand_path("fixtures/b.rb"), 2] }

  before do
    path = Pathname.new(File.expand_path(__FILE__)) + "../../../../fixtures"
    Delfos.application_directories = [path]
  end

  describe "#klass_location" do
    it do
      expect(args.klass_locations(1.class)).to eq []
      expect(args.klass_locations(A)).to eq [a_path]
    end
  end

  describe "#args" do
    it do
      expect(args.args).to eq [A, B]
    end
  end
end
