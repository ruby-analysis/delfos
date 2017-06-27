# frozen_string_literal: true

RSpec.configure do |c|
  c.before(:suite) do |_e|
    FileUtils.rm_rf("./tmp")
  end
end
