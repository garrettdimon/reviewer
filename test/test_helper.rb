# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'reviewer'

require 'minitest/autorun'

def apply_test_configuration!
  # Ensure it's using the test configuration file since
  # some tests intentionally change it to test how it
  # recovers when misconfigured
  Reviewer.configure do |config|
    config.file = 'test/fixtures/files/test_commands.yml'
  end
end

apply_test_configuration!
