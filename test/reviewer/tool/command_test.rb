# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class Tool
    class CommandTest < MiniTest::Test
      def setup
        Reviewer.configure do |config|
          config.file = 'test/fixtures/files/test_commands.yml'
        end
        @settings = Settings.new(:enabled_tool)
        @level = :total_silence
      end

      def test_verbosity_level_changes_command
        total_silence = Command.new(:install, tool_settings: @settings, verbosity_level: :total_silence)
        assert_includes total_silence.to_s, '--quiet > /dev/null'

        no_silence = Command.new(:install, tool_settings: @settings, verbosity_level: :no_silence)
        refute_includes no_silence.to_s, '--quiet'
        refute_includes no_silence.to_s, Verbosity::SEND_TO_DEV_NULL
      end

      def test_install_command_generates_correct_string
        cmd = Command.new(:install, tool_settings: @settings, verbosity_level: @level)

        assert_equal "WITH_SPACES='with spaces'; WORD=second; INTEGER=1; BOOLEAN=true; bundle exec gem install example --quiet > /dev/null", cmd.to_s
      end

      def test_prepare_command_generates_correct_string
        cmd = Command.new(:prepare, tool_settings: @settings, verbosity_level: @level)

        assert_equal "WITH_SPACES='with spaces'; WORD=second; INTEGER=1; BOOLEAN=true; bundle exec example update --quiet > /dev/null", cmd.to_s
      end

      def test_review_command_generates_correct_string
        cmd = Command.new(:review, tool_settings: @settings, verbosity_level: @level)

        assert_equal "WITH_SPACES='with spaces'; WORD=second; INTEGER=1; BOOLEAN=true; bundle exec example review --third 'third flag' --fourth 'fourth flag' --quiet > /dev/null", cmd.to_s
      end

      def test_format_command_generates_correct_string
        cmd = Command.new(:format, tool_settings: @settings, verbosity_level: @level)

        assert_equal "WITH_SPACES='with spaces'; WORD=second; INTEGER=1; BOOLEAN=true; bundle exec example format --quiet > /dev/null", cmd.to_s
      end
    end
  end
end
