# frozen_string_literal: true

require "test_helper"

module Reviewer
  class Tool
    class SettingsTest < MiniTest::Test
      def setup
        @tool = :example
        @config = {
          commands: {
            review: 'example'
          }
        }
        @settings = Settings.new(@tool, config: @config)
      end

      def test_uses_reviewer_configuration_when_config_not_provided
        Reviewer.configure do |config|
          config.file = 'test/fixtures/files/test_commands.yml'
        end

        settings = Settings.new(:enabled_tool)
        assert_equal 'Enabled Tool', settings.name
      end

      def test_exposes_enabled_or_disbled_status_with_enabled_as_default
        assert @settings.enabled?
        refute @settings.disabled?

        @config[:disabled] = true
        @settings = Settings.new(@tool, config: @config)
        refute @settings.enabled?
        assert @settings.disabled?
      end

      def test_provides_the_tool_key
        assert_equal @tool, @settings.key
      end

      def test_provides_the_tool_name_with_the_key_as_default
        assert_equal @tool.to_s.titleize, @settings.name

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
        assert_equal Array.new, @settings.tags

        @config[:tags] = %w{ruby css}
        @settings = Settings.new(@tool, config: @config)
        assert_equal @config[:tags], @settings.tags
      end

      def test_provides_the_tool_links_with_empty_hash_as_default
        assert_equal Hash.new, @settings.links

        @config[:links] = {
          home: 'https://example.com'
        }
        @settings = Settings.new(@tool, config: @config)
        assert_equal @config[:links], @settings.links
      end

      def test_provides_the_tool_environment_variables_with_empty_hash_as_default
        assert_equal Hash.new, @settings.env

        @config[:env] = {
          frictionless: true
        }
        @settings = Settings.new(@tool, config: @config)
        assert_equal @config[:env], @settings.env
      end

      def test_provides_the_tool_flags_with_empty_hash_as_default
        assert_equal Hash.new, @settings.flags

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

      def test_provides_the_tool_quiet_flag_with_empty_string_as_default
        assert_equal '', @settings.quiet_flag

        @config[:commands] = {
          review: 'example review',
          quiet_flag: '--silent'
        }
        @settings = Settings.new(@tool, config: @config)
        assert_equal @config.dig(:commands, :quiet_flag), @settings.quiet_flag
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

      def test_raises_error_without_command_for_review
        @config = {
          commands: {
            format: 'example'
          }
        }
        assert_raises(Settings::MissingReviewCommandError) do
          Settings.new(@tool, config: @config)
        end
      end
    end
  end
end