# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class Command
    class StringTest < MiniTest::Test
      def setup
        @settings = ::Reviewer::Tool::Settings.new(:enabled_tool)
        @level = Reviewer::Command::Verbosity::TOTAL_SILENCE
      end

      def test_verbosity_changes_command
        total_silence = Command::String.new(:install, tool_settings: @settings, verbosity: @level)
        assert_includes total_silence.to_s, '-q > /dev/null'

        no_silence = Command::String.new(:install, tool_settings: @settings, verbosity: :no_silence)
        refute_includes no_silence.to_s, '-q'
        refute_includes no_silence.to_s, Reviewer::Command::String::Verbosity::SEND_TO_DEV_NULL
      end

      def test_can_control_seed_via_string_replacement
        @settings = ::Reviewer::Tool::Settings.new(:dynamic_seed_tool)
        cmd = Command::String.new(:review, tool_settings: @settings, verbosity: @level)
        assert_equal 'ls -c --seed $SEED > /dev/null', cmd.to_s
      end

      def test_install_command_generates_correct_string
        cmd = Command::String.new(:install, tool_settings: @settings, verbosity: @level)

        assert_equal "WITH_SPACES='with spaces' WORD=second INTEGER=1 BOOLEAN=true ls -a -q > /dev/null", cmd.to_s
      end

      def test_prepare_command_generates_correct_string
        cmd = Command::String.new(:prepare, tool_settings: @settings, verbosity: @level)

        assert_equal "WITH_SPACES='with spaces' WORD=second INTEGER=1 BOOLEAN=true ls -b -q > /dev/null", cmd.to_s
      end

      def test_review_command_generates_correct_string
        cmd = Command::String.new(:review, tool_settings: @settings, verbosity: @level)

        assert_equal "WITH_SPACES='with spaces' WORD=second INTEGER=1 BOOLEAN=true ls -c --third 'third flag' --fourth 'fourth flag' -q > /dev/null", cmd.to_s
      end

      def test_format_command_generates_correct_string
        cmd = Command::String.new(:format, tool_settings: @settings, verbosity: @level)

        assert_equal "WITH_SPACES='with spaces' WORD=second INTEGER=1 BOOLEAN=true ls -d -q > /dev/null", cmd.to_s
      end
    end
  end
end
