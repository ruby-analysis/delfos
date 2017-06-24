# frozen_string_literal: true

require_relative "file_system/distance_calculation"
require_relative "file_system/app_directories"
require_relative "file_system/app_files"

module Delfos
  module FileSystem
    def self.distance_calculation(start_file, finish_file)
      DistanceCalculation.new(start_file, finish_file)
    end

    def self.include_file?(file)
      FileSystem::AppDirectories.include_file?(file) && FileSystem::AppFiles.include_file?(file)
    end
  end
end
