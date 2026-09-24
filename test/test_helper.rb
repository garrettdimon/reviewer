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

# The project's docs, fixtures and captured output are UTF-8, so the suite reads text as UTF-8
# regardless of the developer's locale. Tests that exercise a non-UTF-8 locale opt in with
# `with_default_external`. Ruby warns when this changes, so the warning is silenced here.
original_verbose = $VERBOSE
$VERBOSE = nil
Encoding.default_external = Encoding::UTF_8
$VERBOSE = original_verbose

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'reviewer'

require 'minitest/autorun'
require 'minitest/heat'

# Makes it easy to mock process statuses
MockProcessStatus = Struct.new(:exitstatus, :pid, keyword_init: true) do
  def success? = exitstatus.zero?
end

module Minitest
  class Test
    private

    def default_context(arguments: Reviewer::Arguments.new([]), output: Reviewer::Output.new, history: Reviewer.history)
      Reviewer::Context.new(arguments: arguments, output: output, history: history)
    end

    def build_tool(key, history: Reviewer.history)
      config = test_fixture_config.fetch(key.to_sym) { {} }
      Reviewer::Tool.new(key, config: config, history: history)
    end

    def test_fixture_config
      @test_fixture_config ||= Reviewer::Configuration::Loader.configuration(file: Reviewer.configuration.file)
    end

    # Simulates a non-UTF-8 locale (e.g. LC_ALL=C) regardless of the developer's own locale.
    # Ruby warns when this changes, so warnings are silenced while swapping.
    def with_default_external(encoding)
      original = Encoding.default_external
      swap_default_external(encoding)
      yield
    ensure
      swap_default_external(original)
    end

    def swap_default_external(encoding)
      verbose = $VERBOSE
      $VERBOSE = nil
      Encoding.default_external = encoding
    ensure
      $VERBOSE = verbose
    end

    # Temporarily sets environment variables, restoring their previous values afterward
    def with_env(variables)
      previous = variables.keys.to_h { |name| [name, ENV.fetch(name, nil)] }
      variables.each { |name, value| ENV[name] = value }
      yield
    ensure
      previous&.each { |name, value| ENV[name] = value }
    end

    # Runs git fixtures and the code under test without the developer's global or system git
    # configuration, so settings like mandatory commit signing or hook paths can't interfere.
    def with_isolated_git_config(&)
      with_env('GIT_CONFIG_GLOBAL' => File::NULL, 'GIT_CONFIG_NOSYSTEM' => '1', &)
    end

    # Temporarily swaps the Reviewer config file and clears memoized tools.
    # Use for tests that need a missing or alternate config.
    def with_swapped_config(file)
      original_file = Reviewer.configuration.file
      Reviewer.instance_variable_set(:@tools, nil)
      Reviewer.configuration.file = file
      yield
    ensure
      Reviewer.configuration.file = original_file
      Reviewer.instance_variable_set(:@tools, nil)
    end
  end
end

# Configure Reviewer to use test fixtures so tests don't depend on a real .reviewer.yml
Reviewer.reset!
Reviewer.configure do |config|
  config.file = Pathname('test/fixtures/files/test_commands.yml')
  config.history_file = Pathname(Reviewer::Configuration::DEFAULT_HISTORY_LOCATION.sub('.yml', '_test.yml'))
end
