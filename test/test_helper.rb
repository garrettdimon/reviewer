# frozen_string_literal: true

if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start do
    enable_coverage :branch
    minimum_coverage 100
    minimum_coverage_by_file 100
    refuse_coverage_drop
  end

  require 'codecov'
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'reviewer'

require 'dead_end'
require 'minitest/autorun'
require 'minitest/color'

# Makes it easy to mock process statuses
MockProcessStatus = Struct.new(:exitstatus, :pid, keyword_init: true)

def suppressed_output_printer
  ::Logger.new(File::NULL)
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

    # By default, send all the output to dev/null. If there's an explicit need to test the values in
    # a given test, it can be overriden with the Reviewer printer configuration and use
    # `capture_subprocess_io` to record the output to stdout
    config.printer = suppressed_output_printer
  end
end

# In some tests, we want to be able to capture the output and ensure it's the output expected. This
# removes the Null logger so we can see and capture the output.
def disable_output_suppression
  Reviewer.configure do |config|
    config.printer = ::Reviewer::Printer.new
  end
  yield
  Reviewer.configure do |config|
    config.printer = suppressed_output_printer
  end
end

ensure_test_configuration!
