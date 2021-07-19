# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class ConfigurationTest < Minitest::Test
    def test_uses_default_configuration_file
      assert_equal Configuration::DEFAULT_CONFIG_LOCATION, Configuration.new.file.to_s
    end

    def test_config_file_can_be_customized
      overridden_file = '../commands.yml'
      Reviewer.configure do |config|
        config.file = overridden_file
      end
      assert_equal overridden_file, Reviewer.configuration.file
      ensure_test_configuration!
    end

    def test_history_file_can_be_customized
      overridden_file = '../commands_history.yml'
      Reviewer.configure do |config|
        config.history_file = overridden_file
      end
      assert_equal overridden_file, Reviewer.configuration.history_file
      ensure_test_configuration!
    end
  end
end
