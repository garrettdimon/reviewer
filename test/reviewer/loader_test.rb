# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class LoaderTest < MiniTest::Test
    def setup
      @file = Reviewer.configuration.file
    end

    def test_reads_the_yaml_configuration_file
      loader = Loader.new(@file)
      assert loader.configuration.is_a? Hash
    end

    def test_hashes_configuration_with_indiffferent_access
      loader = Loader.new(@file)
      assert loader.configuration.key?(:enabled_tool)
      assert loader.configuration.key?('enabled_tool')
    end

    def test_to_h
      loader_hash = Loader.new(@file).to_h
      assert loader_hash.is_a? Hash
      assert loader_hash.key? :enabled_tool
    end

    def test_fails_gracefully_when_configuration_yaml_missing
      file = 'test/fixtures/files/missing.yml'
      Reviewer.configure do |config|
        config.file = file
      end
      assert_raises(Loader::MissingConfigurationError) { Loader.new(file) }
      ensure_test_configuration!
    end

    def test_fails_gracefully_with_malformed_configuration_yaml
      file = 'test/fixtures/files/test_commands_broken.yml'
      Reviewer.configure do |config|
        config.file = file
      end
      assert_raises(Loader::InvalidConfigurationError) { Loader.new(file) }
      ensure_test_configuration!
    end
  end
end
