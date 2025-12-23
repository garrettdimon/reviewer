# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class Command
    class StringTest < Minitest::Test
      def setup
        @settings = ::Reviewer::Tool::Settings.new(:enabled_tool)
      end

      def test_can_control_seed_via_string_replacement
        @settings = ::Reviewer::Tool::Settings.new(:dynamic_seed_tool)
        cmd = Command::String.new(:review, tool_settings: @settings)
        assert_equal 'ls -c --seed $SEED', cmd.to_s
      end

      def test_install_command_generates_correct_string
        cmd = Command::String.new(:install, tool_settings: @settings)

        assert_equal "WITH_SPACES='with spaces' WORD=second INTEGER=1 BOOLEAN=true ls -a", cmd.to_s
      end

      def test_prepare_command_generates_correct_string
        cmd = Command::String.new(:prepare, tool_settings: @settings)

        assert_equal "WITH_SPACES='with spaces' WORD=second INTEGER=1 BOOLEAN=true ls -b", cmd.to_s
      end

      def test_review_command_generates_correct_string
        cmd = Command::String.new(:review, tool_settings: @settings)

        assert_equal "WITH_SPACES='with spaces' WORD=second INTEGER=1 BOOLEAN=true ls -c --third 'third flag' --fourth 'fourth flag'", cmd.to_s
      end

      def test_format_command_generates_correct_string
        cmd = Command::String.new(:format, tool_settings: @settings)

        assert_equal "WITH_SPACES='with spaces' WORD=second INTEGER=1 BOOLEAN=true ls -d", cmd.to_s
      end

      def test_appends_files_when_tool_supports_file_targeting
        settings = ::Reviewer::Tool::Settings.new(:file_targeting_tool)
        files = %w[lib/foo.rb lib/bar.rb]
        cmd = Command::String.new(:review, tool_settings: settings, files: files)

        assert_equal 'rubocop lib/foo.rb lib/bar.rb', cmd.to_s
      end

      def test_appends_files_with_flag_and_custom_separator
        settings = ::Reviewer::Tool::Settings.new(:file_targeting_with_flag_tool)
        files = %w[lib/foo.rb lib/bar.rb]
        cmd = Command::String.new(:review, tool_settings: settings, files: files)

        assert_equal 'custom-lint --files lib/foo.rb,lib/bar.rb', cmd.to_s
      end

      def test_does_not_append_files_when_tool_lacks_file_support
        files = %w[lib/foo.rb lib/bar.rb]
        cmd = Command::String.new(:review, tool_settings: @settings, files: files)

        # Should not include files - enabled_tool has no files: config
        refute_includes cmd.to_s, 'lib/foo.rb'
      end

      def test_does_not_append_files_when_no_files_provided
        settings = ::Reviewer::Tool::Settings.new(:file_targeting_tool)
        cmd = Command::String.new(:review, tool_settings: settings, files: [])

        assert_equal 'rubocop', cmd.to_s
      end
    end
  end
end
