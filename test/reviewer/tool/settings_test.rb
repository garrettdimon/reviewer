# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class Tool
    class SettingsTest < MiniTest::Test # rubocop:disable Metrics/ClassLength
      def setup
        @tool = :example
        @config = {
          commands: {
            review: 'example'
          }
        }
        @settings = Settings.new(@tool, config: @config)
      end

      def test_compares_settings_values_for_equality
        settings_one = Settings.new(:enabled_tool)
        settings_two = Settings.new(:enabled_tool)
        settings_three = Settings.new(:disabled_tool)
        assert settings_one == settings_two
        assert settings_one.eql?(settings_two)
        refute settings_one == settings_three
        refute settings_one.eql?(settings_three)
      end

      def test_uses_reviewer_configuration_when_config_not_provided
        settings = Settings.new(:enabled_tool)
        assert_equal 'Enabled Test Tool', settings.name
      end

      def test_exposes_enabled_or_disbled_status_with_enabled_as_default
        assert @settings.enabled?
        refute @settings.disabled?

        @config[:disabled] = true
        @settings = Settings.new(@tool, config: @config)
        refute @settings.enabled?
        assert @settings.disabled?
      end

      def test_provides_the_tool_name_with_the_key_as_default
        assert_equal @tool, @settings.key
        assert_equal @tool.to_s.capitalize, @settings.name

        @config[:name] = 'Tool Name'
        @settings = Settings.new(@tool, config: @config)
        assert_equal @config[:name], @settings.name
      end

      def test_provides_the_tool_description
        assert_equal "(No description provided for '#{@settings.name}')", @settings.description

        @config[:description] = 'description'
        @settings = Settings.new(@tool, config: @config)
        assert_equal @config[:description], @settings.description
      end

      def test_provides_the_tool_tags_with_empty_array_as_default
        assert_equal([], @settings.tags)

        @config[:tags] = %w[ruby css]
        @settings = Settings.new(@tool, config: @config)
        assert_equal @config[:tags], @settings.tags
      end

      def test_provides_the_tool_verbosities_with_empty_hash_as_default
        assert_equal({}, @settings.verbosities)

        @config[:verbosities] = { quiet: '--quiet' }
        @settings = Settings.new(@tool, config: @config)
        assert_equal @config[:verbosities], @settings.verbosities
      end

      def test_provides_the_tool_links_with_empty_hash_as_default
        assert_equal({}, @settings.links)

        @config[:links] = { home: 'https://example.com' }
        @settings = Settings.new(@tool, config: @config)
        assert_equal @config[:links], @settings.links
      end

      def test_provides_the_tool_environment_variables_with_empty_hash_as_default
        assert_equal({}, @settings.env)

        @config[:env] = { frictionless: true }
        @settings = Settings.new(@tool, config: @config)
        assert_equal @config[:env], @settings.env
      end

      def test_provides_the_tool_flags_with_empty_hash_as_default
        assert_equal({}, @settings.flags)

        @config[:flags] = {
          q: true,
          verbose: false
        }
        @settings = Settings.new(@tool, config: @config)
        assert_equal @config[:flags], @settings.flags
      end

      def test_provides_the_tool_max_exit_status_with_zero_as_default
        assert_equal 0, @settings.max_exit_status

        @config[:commands] = {
          review: 'example review',
          max_exit_status: 3
        }
        @settings = Settings.new(@tool, config: @config)
        assert_equal @config.dig(:commands, :max_exit_status), @settings.max_exit_status
      end

      def test_provides_the_tool_quiet_option_with_empty_string_as_default
        assert_equal '', @settings.quiet_option

        @config[:commands] = {
          review: 'example review',
          quiet_option: '--silent'
        }
        @settings = Settings.new(@tool, config: @config)
        assert_equal @config.dig(:commands, :quiet_option), @settings.quiet_option
      end

      def test_provides_the_tool_commands_with_empty_hash_as_default
        assert_equal @config[:commands], @settings.commands

        @config[:commands] = {
          install: 'example install',
          prepare: 'example prepare',
          review: 'example review'
        }
        @settings = Settings.new(@tool, config: @config)
        assert_equal @config[:commands], @settings.commands
      end
    end
  end
end
