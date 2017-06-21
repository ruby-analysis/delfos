# frozen_string_literal: true

require "logger"

module DelfosSpecs
  class << self
    attr_accessor :logger
  end
end

DelfosSpecs.logger = Logger.new(STDOUT).tap do |l|
  l.level = ENV["LOG_LEVEL"] ? ENV["LOG_LEVEL"].to_i : Logger::ERROR
  l.progname = "Delfos test"
end
