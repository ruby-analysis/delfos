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
    expect(BasicObject).
      to receive(:_delfos_added_methods).
      and_return({}).
      at_least(:once)

    expect(A).
      to receive(:_delfos_added_methods).
      and_return(added_methods_a).
      at_least(:once)
    allow(B).
      to receive(:_delfos_added_methods).
      and_return(added_methods_b).
      at_least(:once)
  end

  let(:added_methods_a) do
    { "instance_method_some_method" => ["/Users/markburns/code/delfos/fixtures/a.rb", 4] }
  end

  let(:added_methods_b) do
    { "instance_method_another_method" => ["/Users/markburns/code/delfos/fixtures/b.rb", 2] }
  end

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
