# frozen_string_literal: true
require "spec_helper"
require_relative "delfos"

describe Delfos do
  describe "#application_directories=" do
    it "requires the monkey patching file" do
      dir = double "Directories"
      expect(Delfos).to receive(:load).with "delfos/perform_patching.rb"
      allow(Delfos).to receive(:load).with "delfos/remove_patching.rb"

      Delfos.setup!(application_directories: dir)

      expect(Delfos.application_directories).to eq dir
    end
  end
end
