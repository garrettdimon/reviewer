# frozen_string_literal: true

require 'test_helper'

module Reviewer
  module Setup
    class GeneratorTest < Minitest::Test
      def test_generates_valid_yaml
        generator = Generator.new([:rubocop])
        yaml = generator.generate

        parsed = YAML.safe_load(yaml)
        assert_kind_of Hash, parsed
      end

      def test_generates_config_for_single_tool
        generator = Generator.new([:rubocop])
        yaml = generator.generate

        parsed = YAML.safe_load(yaml)
        assert parsed.key?('rubocop')
        assert parsed['rubocop']['commands'].key?('review')
      end

      def test_generates_config_for_multiple_tools
        generator = Generator.new(%i[rubocop reek tests])
        yaml = generator.generate

        parsed = YAML.safe_load(yaml)
        assert parsed.key?('rubocop')
        assert parsed.key?('reek')
        assert parsed.key?('tests')
      end

      def test_excludes_detect_key
        generator = Generator.new([:rubocop])
        yaml = generator.generate

        parsed = YAML.safe_load(yaml)
        refute parsed['rubocop'].key?('detect')
      end

      def test_includes_name_and_description
        generator = Generator.new([:rubocop])
        yaml = generator.generate

        parsed = YAML.safe_load(yaml)
        assert_equal 'RuboCop', parsed['rubocop']['name']
        assert parsed['rubocop'].key?('description')
      end

      def test_includes_files_config_when_present
        generator = Generator.new([:rubocop])
        yaml = generator.generate

        parsed = YAML.safe_load(yaml)
        assert parsed['rubocop'].key?('files')
        assert_equal '*.rb', parsed['rubocop']['files']['pattern']
      end

      def test_skips_unknown_keys
        generator = Generator.new(%i[rubocop nonexistent_tool])
        yaml = generator.generate

        parsed = YAML.safe_load(yaml)
        assert parsed.key?('rubocop')
        refute parsed.key?('nonexistent_tool')
      end

      def test_empty_keys_returns_empty_yaml
        generator = Generator.new([])
        yaml = generator.generate

        parsed = YAML.safe_load(yaml)
        assert_equal({}, parsed)
      end

      def test_output_includes_comments_with_description
        generator = Generator.new([:rubocop])
        yaml = generator.generate

        assert_match(/^# /, yaml)
        assert_match(/^# Review Ruby syntax/, yaml)
      end

      def test_preserves_node_catalog_commands
        keys = %i[eslint prettier stylelint typescript biome]
        parsed = YAML.safe_load(Generator.new(keys).generate)
        expected = keys.to_h do |key|
          [key.to_s, Catalog.config_for(key)[:commands].transform_keys(&:to_s)]
        end
        actual = parsed.transform_values { |config| config.fetch('commands') }

        assert_equal expected, actual
      end

      def test_does_not_alter_ruby_commands
        parsed = YAML.safe_load(Generator.new([:rubocop]).generate)

        assert_match(/^bundle exec/, parsed['rubocop']['commands']['review'])
      end

      def test_includes_rspec_files_config
        generator = Generator.new([:specs])
        yaml = generator.generate

        parsed = YAML.safe_load(yaml)
        assert parsed['specs'].key?('files')
        assert_equal '*_spec.rb', parsed['specs']['files']['pattern']
        assert_equal 'rspec', parsed['specs']['files']['map_to_tests']
      end

      def test_includes_file_scoped_commands_in_files_block
        generator = Generator.new([:tests])
        yaml = generator.generate

        parsed = YAML.safe_load(yaml)
        files = parsed['tests']['files']
        assert_equal 'bundle exec ruby -Itest', files['review']
      end

      def test_minitest_review_command_is_rake_test
        generator = Generator.new([:tests])
        yaml = generator.generate

        parsed = YAML.safe_load(yaml)
        assert_equal 'bundle exec rake test', parsed['tests']['commands']['review']
      end
    end
  end
end
