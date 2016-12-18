# frozen_string_literal: true
require "spec_helper"
require_relative "delfos"

describe Delfos do
  describe "#application_directories=" do
    it "requires the monkey patching file" do
      dir = ["some/dir"]
      expect(Delfos::Setup).to receive(:load).with "delfos/patching/basic_object.rb"
      allow(Delfos::Setup).to receive(:load).with "delfos/patching/basic_object_remove.rb"

      Delfos.setup!(application_directories: dir)

      expect(Delfos.application_directories).to eq [Pathname.new(File.expand_path(dir.first))]
    end
  end
end
