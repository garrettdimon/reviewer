# frozen_string_literal: true

if ENV['COVERAGE']
  require 'simplecov'
  require 'simplecov_json_formatter'

  SimpleCov.print_error_status = false
  SimpleCov.start do
    enable_coverage :branch
    minimum_coverage 100
    minimum_coverage_by_file 100
    refuse_coverage_drop
  end

  SimpleCov.at_exit do
    # SimpleCov.result.format!
  end

  if ENV['CI'] == 'true'
    require 'codecov'
    SimpleCov.formatter = SimpleCov::Formatter::Codecov
  else
    # With the JSON formatter, Reviewwer can look at the results and show guidance without needing
    # to open the HTML view
    formatters = [
      SimpleCov::Formatter::SimpleFormatter,
      SimpleCov::Formatter::HTMLFormatter,
      SimpleCov::Formatter::JSONFormatter
    ]
    SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new(formatters)
  end
end

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'reviewer'

require 'dead_end'
require 'minitest/autorun'
require 'minitest/heat'

# Makes it easy to mock process statuses
MockProcessStatus = Struct.new(:exitstatus, :pid, keyword_init: true)

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
