# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'reviewer'

require 'minitest/autorun'
require 'minitest/color'

# Ensure it's using the test configuration file since some tests intentionally
# change it to test how it recovers when misconfigured
def ensure_test_configuration!
  # Use the test configuration file that has predictable example coverage
  test_configuration_file = 'test/fixtures/files/test_commands.yml'

  # Use a test location for the history file so it doesn't overwrite the primary history file
  test_history_file = Reviewer::Configuration::DEFAULT_HISTORY_LOCATION.sub('.yml', '_test.yml')

  return if Reviewer.configuration.file == test_configuration_file &&
            Reviewer.configuration.history_file == test_history_file

  Reviewer.configure do |config|
    config.file = test_configuration_file
    config.history_file = test_history_file
  end
end

ensure_test_configuration!
