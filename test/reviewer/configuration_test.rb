# frozen_string_literal: true

require "test_helper"

module Reviewer
  class ConfigurationTest < Minitest::Test
    def setup
    end

    def test_file_has_default
      config = Configuration.new
      assert config.file = 'commands.yml'
    end

    def test_file_can_be_set
      config = Configuration.new
      config.file = '../commands.yml'
      assert config.file = '../commands.yml'
    end
  end
end
