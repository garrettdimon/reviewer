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

class Minitest::Test
  private

  def default_context(arguments: Reviewer::Arguments.new([]), output: Reviewer::Output.new, history: Reviewer.history)
    Reviewer::Context.new(arguments: arguments, output: output, history: history)
  end
end

# Configure Reviewer to use test fixtures so tests don't depend on a real .reviewer.yml
Reviewer.reset!
Reviewer.configure do |config|
  config.file = Pathname('test/fixtures/files/test_commands.yml')
  config.history_file = Pathname(Reviewer::Configuration::DEFAULT_HISTORY_LOCATION.sub('.yml', '_test.yml'))
end
