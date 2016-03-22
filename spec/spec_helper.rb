# frozen_string_literal: true
$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require "byebug"

RSpec.configure do |c|
  c.before(:suite) do
    Delfos.setup!(application_directories: [])
    session = ::Neo4j::Session.open(*Delfos.neo4j_config)

    ::Neo4j::Session.query <<-QUERY
      MATCH (m)-[rel]->(n)
      DELETE m,rel,n
    QUERY
  end

  c.before(:each) do
    Delfos.reset!
  end

  c.after(:each) do
    require_relative "../lib/delfos"
    Delfos.reset!
  end
end

def expand_fixture_path(path = "")
  s = File.join File.expand_path(fixture_path), path

  Pathname.new(s).realpath
end

def fixture_path
  Pathname.new("./fixtures/tree").realpath
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
