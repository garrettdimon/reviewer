# frozen_string_literal: true

require "test_helper"

module Reviewer
  class ConfigurationTest < Minitest::Test
    def setup
    end

    def test_file_has_default
      config = Configuration.new
      assert_equal config.file, "#{Configuration::DEFAULT_CONFIGURATION_PATH}/#{Configuration::DEFAULT_CONFIGURATION_FILE}"
    end

    def test_file_can_be_set
      overridden_file = '../commands.yml'
      Reviewer.configure do |config|
        config.file = overridden_file
      end
      assert_equal overridden_file, Reviewer.configuration.file
    end

    def test_loads_tool_configuration_settings
      Reviewer.configure do |config|
        config.file = 'test/fixtures/files/test_commands.yml'
      end
      tools_settings = Reviewer.configuration.tools
      assert tools_settings.is_a? Hash
      assert tools_settings.key?(:enabled_tool)
    end
  end
end
