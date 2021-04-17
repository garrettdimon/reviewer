# frozen_string_literal: true

require "test_helper"

module Reviewer
  module Tools
    class LoaderTest < MiniTest::Test
      def setup
        Reviewer.configure do |config|
          config.file = 'test/fixtures/files/test_commands.yml'
        end
      end

      def teardown
        Reviewer.reset
      end

      def test_reads_the_yaml_configuration_file
        loader = Loader.new
        assert loader.configuration.is_a? Hash
      end

      def test_hashes_configuration_with_indiffferent_access
        loader = Loader.new
        assert loader.configuration.key?(:enabled)
        assert loader.configuration.key?('enabled')
      end

      def test_fails_gracefully_when_configuration_yaml_missing
        Reviewer.configure do |config|
          config.file = 'test/fixtures/files/missing.yml'
        end
        assert_raises(Loader::MissingConfigurationError) { Loader.new }
      end

      def test_fails_gracefully_with_mailformed_configuration_yaml
        Reviewer.configure do |config|
          config.file = 'test/fixtures/files/test_commands_broken.yml'
        end
        assert_raises(Loader::InvalidConfigurationError) { Loader.new }
      end
    end
  end
end
