# frozen_string_literal: true

require "test_helper"

module Reviewer
  module Tool
    class SettingsTest < MiniTest::Test
      def setup
        @tool = :example
        @config = {
          commands: {
            review: 'example'
          }
        }
      end

      def test_exposes_enabled_or_disbled_status_with_enabled_as_default
        settings = ::Reviewer::Tool::Settings.new(tool: @tool, config: @config)
        assert settings.enabled?
        refute settings.disabled?

        @config[:disabled] = true
        settings = ::Reviewer::Tool::Settings.new(tool: @tool, config: @config)
        refute settings.enabled?
        assert settings.disabled?
      end

      def test_provides_the_tool_name_as_string_or_key
        settings = ::Reviewer::Tool::Settings.new(tool: @tool, config: @config)
        assert_equal @tool.to_s, settings.name
        assert_equal @tool, settings.key
      end

      def test_provides_the_tool_description
        settings = ::Reviewer::Tool::Settings.new(tool: @tool, config: @config)
        assert_equal '', settings.description

        @config[:description] = 'description'
        settings = ::Reviewer::Tool::Settings.new(tool: @tool, config: @config)
        assert_equal @config[:description], settings.description
      end

      def test_provides_the_tool_tags_with_empty_array_as_default
        settings = ::Reviewer::Tool::Settings.new(tool: @tool, config: @config)
        assert_equal Array.new, settings.tags

        @config[:tags] = %w{ruby css}
        settings = ::Reviewer::Tool::Settings.new(tool: @tool, config: @config)
        assert_equal @config[:tags], settings.tags
      end

      def test_provides_the_tool_links_with_empty_hash_as_default
        settings = ::Reviewer::Tool::Settings.new(tool: @tool, config: @config)
        assert_equal Hash.new, settings.links

        @config[:links] = {
          home: 'https://example.com'
        }
        settings = ::Reviewer::Tool::Settings.new(tool: @tool, config: @config)
        assert_equal @config[:links], settings.links
      end

      def test_provides_the_tool_environment_variables_with_empty_hash_as_default
        settings = ::Reviewer::Tool::Settings.new(tool: @tool, config: @config)
        assert_equal Hash.new, settings.env

        @config[:env] = {
          frictionless: true
        }
        settings = ::Reviewer::Tool::Settings.new(tool: @tool, config: @config)
        assert_equal @config[:env], settings.env
      end

      def test_provides_the_tool_flags_with_empty_hash_as_default
        settings = ::Reviewer::Tool::Settings.new(tool: @tool, config: @config)
        assert_equal Hash.new, settings.flags

        @config[:flags] = {
          q: true,
          verbose: false
        }
        settings = ::Reviewer::Tool::Settings.new(tool: @tool, config: @config)
        assert_equal @config[:flags], settings.flags
      end

      def test_provides_the_tool_commands_with_empty_hash_as_default
        settings = ::Reviewer::Tool::Settings.new(tool: @tool, config: @config)
        assert_equal @config[:commands], settings.commands

        @config[:commands] = {
          install: 'example install',
          prepare: 'example prepare',
          review: 'example review'
        }
        settings = ::Reviewer::Tool::Settings.new(tool: @tool, config: @config)
        assert_equal @config[:commands], settings.commands
      end

      def test_raises_error_without_command_for_review
        @config = {
          commands: {
            format: 'example'
          }
        }
        assert_raises(Settings::MissingReviewCommandError) do
          Settings.new(tool: @tool, config: @config)
        end
      end
    end
  end
end
