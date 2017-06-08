# frozen_string_literal: true
require "logger"

$delfos_test_logger = Logger.new(STDOUT, progname: "Delfos test", level: Logger::ERROR)
