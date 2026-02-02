# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class Configuration
    class LoaderTest < Minitest::Test
      def test_reads_the_yaml_configuration_file
        loader = Loader.new(file: config_file)
        assert loader.configuration.is_a? Hash
      end

      def test_provides_class_method_for_loading_configuration
        loader = Loader.configuration(file: config_file)
        assert loader.is_a? Hash
      end

      def test_hashes_configuration_with_symbol_keys
        loader = Loader.new(file: config_file)
        assert loader.configuration.key?(:enabled_tool)
        refute loader.configuration.key?('enabled_tool')
      end

      def test_to_h
        loader_hash = Loader.new(file: config_file).to_h
        assert loader_hash.is_a? Hash
        assert loader_hash.key? :enabled_tool
      end

      def test_fails_gracefully_when_configuration_yaml_missing
        assert_raises(Loader::MissingConfigurationError) { Loader.new(file: 'test/fixtures/files/missing.yml') }
      end

      def test_fails_gracefully_with_malformed_configuration_yaml
        assert_raises(Loader::InvalidConfigurationError) { Loader.new(file: 'test/fixtures/files/test_commands_broken.yml') }
      end

      def test_review_commands_present_returns_true_for_valid_config
        loader = Loader.new(file: config_file)
        assert loader.review_commands_present?
      end

      def test_raises_error_without_command_for_review
        assert_raises(Loader::MissingReviewCommandError) { Loader.new(file: 'test/fixtures/files/test_commands_no_review_command.yaml') }
      end

      private

      def config_file = Reviewer.configuration.file
    end
  end
end
