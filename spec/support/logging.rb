# frozen_string_literal: true
require "logger"

$delfos_test_logger = Logger.new(STDOUT).tap do |l|
  l.level = Logger::ERROR
  l.progname = "Delfos test"
end
