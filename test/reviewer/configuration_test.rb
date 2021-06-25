# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class ConfigurationTest < Minitest::Test
    def setup
      ensure_test_configuration!
    end

    def test_uses_default_configuration_file
      assert_equal Configuration::DEFAULT_FILE, Configuration.new.file
    end

    def test_file_can_be_set
      overridden_file = '../commands.yml'
      Reviewer.configure do |config|
        config.file = overridden_file
      end
      assert_equal overridden_file, Reviewer.configuration.file
      ensure_test_configuration!
    end
  end
end
