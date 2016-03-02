require 'spec_helper'
require_relative 'delfos'

describe Delfos do
  describe "#application_directories=" do
    it 'requires the monkey patching file' do
      dir = double "Directories"
      expect(Delfos).to receive(:require_relative).with "delfos/perform_patching"

      Delfos.setup!(application_directories: dir)

      expect(Delfos.application_directories).to eq dir
    end
  end
end
