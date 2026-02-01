# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class ConfigurationTest < Minitest::Test
    def test_uses_default_configuration_file
      assert_equal Configuration::DEFAULT_CONFIG_LOCATION, Configuration.new.file.to_s
    end

    def test_config_file_can_be_customized
      config = Configuration.new
      config.file = '../commands.yml'
      assert_equal '../commands.yml', config.file
    end

    def test_history_file_can_be_customized
      config = Configuration.new
      config.history_file = '../commands_history.yml'
      assert_equal '../commands_history.yml', config.history_file
    end
  end
end
