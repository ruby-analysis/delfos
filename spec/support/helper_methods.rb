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

  def match_file_array(files, other_files)
    format = ->(f) { f.to_s.gsub(Regexp.escape(fixture_path.to_s), "") }

    files = files.map(&format)
    other_files = other_files.map(&format)

    expect(files).to match_array(other_files.map { |f| t(f) }.map(&format))
  end

  def strip_whitespace(string)
    string.
      gsub(/^\s+/, "").
      gsub(/ +/, " ").
      gsub("\n\n", "\n").
      tr("\n", " ")
  end
end

RSpec.configure do |c|
  c.include DelfosSpecHelpers
end
