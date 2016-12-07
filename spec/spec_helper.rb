# frozen_string_literal: true
$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require "byebug"
require "delfos"
require "pathname"
ENV["DELFOS_DEVELOPMENT"] = "true"

ENV["NEO4J_URL"]      ||= "http://localhost:7476"
ENV["NEO4J_USERNAME"] ||= "neo4j"
ENV["NEO4J_PASSWORD"] ||= "password"

module DelfosSpecHelpers
  def expand_fixture_path(path = "")
    s = File.join File.expand_path(fixture_path), path

    Pathname.new(s).realpath
  end

  def fixture_path
    Pathname.new("./fixtures").realpath
  end

  def t(path)
    Pathname.new(File.join(fixture_path, path)).realpath
  end

  def match_file_array(a, b)
    format = ->(f) { f.to_s.gsub(Regexp.escape(fixture_path.to_s), "") }

    a = a.map &format
    b = b.map &format

    expect(a).to match_array(b.map { |f| t(f) }.map(&format))
  end
end

module TimeoutHelpers
  TIMEOUT_VALUE = (ENV["TIMEOUT"] || (ENV["CI"] ? 20 : 0.0)).to_f

  def timeout
    return yield if TIMEOUT_VALUE == 0.0

    begin
      Timeout.timeout TIMEOUT_VALUE do
        yield
      end
    rescue Timeout::Error
      Delfos.reset!
      puts "Rescuing timeout"
      raise
    end
  end
end

RSpec.configure do |c|
  c.include DelfosSpecHelpers

  c.expect_with :rspec do |c|
    c.syntax = :expect
  end

  c.include TimeoutHelpers
  c.mock_with :rspec do |c|
    c.syntax = :expect
  end

  c.before(:suite) do
    begin
      Delfos.wipe_db!
    rescue Errno::ECONNREFUSED => e
      puts "*" * 80
      puts "*" * 80
      puts "*" * 80
      puts "Failed to connect to Neo4j:"
      puts Delfos.neo4j
      puts "Start Neo4j or set the following environment variables:"
      puts "  NEO4J_URL"
      puts "  NEO4J_USERNAME"
      puts "  NEO4J_PASSWORD"
      puts "*" * 80
      puts "*" * 80
      puts "*" * 80
    end
  end

  c.around(:each) do |e|
    Delfos.reset!
    timeout { e.run }
  end
end
