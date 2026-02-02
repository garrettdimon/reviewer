# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class Batch
    class FormatterTest < Minitest::Test
      def setup
        @output = Output.new
        @formatter = Batch::Formatter.new(@output)
      end

      def test_no_failures_to_retry
        out, _err = capture_subprocess_io { @formatter.no_failures_to_retry }
        assert_match(/No failures to retry/i, out)
      end

      def test_no_previous_run
        out, _err = capture_subprocess_io { @formatter.no_previous_run }
        assert_match(/No previous run found/i, out)
      end

      def test_run_summary_shows_tool_names
        entries = [
          { name: 'Rubocop', files: [] },
          { name: 'Reek', files: [] }
        ]
        out, _err = capture_subprocess_io { @formatter.run_summary(entries) }
        assert_match(/Rubocop/, out)
        assert_match(/Reek/, out)
      end

      def test_run_summary_shows_files_under_tool
        entries = [
          { name: 'Rubocop', files: ['lib/reviewer/batch.rb', 'lib/reviewer/command.rb'] }
        ]
        out, _err = capture_subprocess_io { @formatter.run_summary(entries) }
        assert_match(/Rubocop/, out)
        assert_match(%r{lib/reviewer/batch.rb}, out)
        assert_match(%r{lib/reviewer/command.rb}, out)
      end

      def test_run_summary_omits_files_when_empty
        entries = [
          { name: 'Rubocop', files: [] }
        ]
        out, _err = capture_subprocess_io { @formatter.run_summary(entries) }
        assert_match(/Rubocop/, out)
        refute_match(%r{lib/}, out)
      end

      def test_run_summary_skips_output_when_empty
        out, _err = capture_subprocess_io { @formatter.run_summary([]) }
        assert_empty out
      end

      def test_summary_shows_checkmark_and_timing
        out, _err = capture_subprocess_io { @formatter.summary(3, 1.5) }
        assert_match(/✓/, out)
        assert_match(/~1.5 seconds/, out)
        assert_match(/3 tools/, out)
      end

      def test_missing_tools_shows_count
        tools = [Tool.new(:missing_with_install)]
        out, _err = capture_subprocess_io { @formatter.missing_tools(tools) }
        assert_match(/1 not installed/i, out)
      end

      def test_missing_tools_shows_tool_name
        tools = [Tool.new(:missing_with_install)]
        out, _err = capture_subprocess_io { @formatter.missing_tools(tools) }
        assert_match(/Missing With Install/i, out)
      end

      def test_missing_tools_shows_install_hint
        tools = [Tool.new(:missing_with_install)]
        out, _err = capture_subprocess_io { @formatter.missing_tools(tools) }
        assert_match(/gem install missing-tool/, out)
      end

      def test_missing_tools_pluralizes_for_multiple
        tools = [Tool.new(:missing_with_install), Tool.new(:missing_command)]
        out, _err = capture_subprocess_io { @formatter.missing_tools(tools) }
        assert_match(/2 not installed/i, out)
      end
    end
  end
end
