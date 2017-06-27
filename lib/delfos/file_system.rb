# frozen_string_literal: true

require_relative "file_system/distance_calculation"
require_relative "file_system/app_directories"
require_relative "file_system/app_files"

module Delfos
  module FileSystem
    def self.distance_calculation(start_file, finish_file)
      DistanceCalculation.new(start_file, finish_file)
    end

    def self.app_directories(included, excluded)
      AppDirectories.new(included, excluded)
    end

    def self.app_files(included, excluded)
      AppFiles.new(included, excluded)
    end
  end
end
