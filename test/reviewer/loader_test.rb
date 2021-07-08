# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class LoaderTest < MiniTest::Test
    def test_reads_the_yaml_configuration_file
      loader = Loader.new
      assert loader.configuration.is_a? Hash
    end

    def test_provides_class_method_for_loading_configuration
      loader = Loader.configuration
      assert loader.is_a? Hash
    end

    def test_hashes_configuration_with_indiffferent_access
      loader = Loader.new
      assert loader.configuration.key?(:enabled_tool)
      assert loader.configuration.key?('enabled_tool')
    end

    def test_to_h
      loader_hash = Loader.new.to_h
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

    def test_raises_error_without_command_for_review
      file = 'test/fixtures/files/test_commands_no_review_command.yaml'
      Reviewer.configure do |config|
        config.file = file
      end
      assert_raises(Loader::MissingReviewCommandError) { Loader.new(file) }
      ensure_test_configuration!
    end
  end
end
