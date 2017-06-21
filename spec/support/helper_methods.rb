# frozen_string_literal: true

module DelfosSpecHelpers
  extend self

  def expand_fixture_path(path = "")
    s = File.join File.expand_path(fixture_path), path

    pathname_klass.new(s).realpath
  end

  def fixture_path
    pathname_klass.new("./fixtures").realpath
  end

  def t(path)
    pathname_klass.new(File.join(fixture_path, path)).realpath
  end

  def pathname_klass
    Pathname
  end

  def match_file_array(a, b)
    format = ->(f) { f.to_s.gsub(Regexp.escape(fixture_path.to_s), "") }

    a = a.map(&format)
    b = b.map(&format)

    expect(a).to match_array(b.map { |f| t(f) }.map(&format))
  end

  def strip_whitespace(s)
    s.
      gsub(/^\s+/, "").
      gsub(/ +/, " ").
      gsub("\n\n", "\n").
      gsub("\n", " ")
  end
end

RSpec.configure do |c|
  c.include DelfosSpecHelpers
end
