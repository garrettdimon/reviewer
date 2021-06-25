# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'reviewer'

require 'minitest/autorun'
require 'minitest/color'


# Ensure it's using the test configuration file since some tests intentionally
# change it to test how it recovers when misconfigured
def ensure_test_configuration!
  test_configuration_file = 'test/fixtures/files/test_commands.yml'

  return if Reviewer.configuration.file == test_configuration_file

  Reviewer.configure do |config|
    config.file = test_configuration_file
  end
end

ensure_test_configuration!
