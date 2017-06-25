# frozen_string_literal: true

# This class should be ignored by method tracing
class AppConfig
  def self.configure
    @some_config_value = nil
  end
end
