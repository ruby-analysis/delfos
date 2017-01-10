# frozen_string_literal: true
require "logger"

$delfos_test_logger = Logger.new(STDOUT)

def $delfos_test_logger.level=(l)
  @level = l
end

$delfos_test_logger.progname = "Delfos test"
$delfos_test_logger.level = Logger::ERROR
