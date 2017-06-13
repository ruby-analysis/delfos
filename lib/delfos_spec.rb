# frozen_string_literal: true

require "spec_helper"
require_relative "delfos"

describe Delfos do
  describe "#application_directories=" do
    it do
      dir = ["some/dir"]

      Delfos.setup!(application_directories: dir)

      expect(Delfos.application_directories).to eq [Delfos::FileSystem::Pathname.new(File.expand_path(dir.first))]
    end
  end
end
