# frozen_string_literal: true

if ENV['COVERAGE'] || ENV['CI']
  require 'simplecov'
  require 'simplecov_json_formatter'

  SimpleCov.print_error_status = false
  SimpleCov.start do
    enable_coverage :branch
    minimum_coverage 90
  end

  formatters = [
    SimpleCov::Formatter::JSONFormatter,
    SimpleCov::Formatter::HTMLFormatter
  ]
  SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new(formatters)
end

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'reviewer'

require 'minitest/autorun'
require 'minitest/heat'

# Makes it easy to mock process statuses
MockProcessStatus = Struct.new(:exitstatus, :pid, keyword_init: true) do
  def success? = exitstatus.zero?
end

# Ensure it's using the test configuration file since some tests intentionally
# change it to test how it recovers when misconfigured
def ensure_test_configuration!
  Reviewer.reset!
  Reviewer.configure do |config|
    # Use the test configuration file that has predictable example coverage
    config.file = Pathname('test/fixtures/files/test_commands.yml')

    # Use a test location for the history file so it doesn't overwrite the primary history file
    config.history_file = Pathname(Reviewer::Configuration::DEFAULT_HISTORY_LOCATION.sub('.yml', '_test.yml'))
  end
end

ensure_test_configuration!
