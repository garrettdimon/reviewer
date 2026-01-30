# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class OutputTest < Minitest::Test
    def setup
      @output = Output.new
    end

    def test_tool_summary
      tool = Tool.new(:enabled_tool)
      out, _err = capture_subprocess_io { @output.tool_summary(tool) }
      assert_match(/#{tool.name}/i, out)
      assert_match(/#{tool.description}/i, out)
    end

    def test_newline
      out, _err = capture_subprocess_io { @output.newline }
      assert_match(/\n/i, out)
    end

    def test_divider
      out, _err = capture_subprocess_io { @output.divider }
      assert_match(/#{Output::DIVIDER}/i, out)
    end

    def test_current_command
      command_string = 'ls -la'
      out, _err = capture_subprocess_io { @output.current_command(command_string) }
      assert_match(/#{command_string}/, out)
      refute_match(/Running:/i, out)
    end

    def test_success_without_prep
      timer = Shell::Timer.new(main: 1.2345)
      out, _err = capture_subprocess_io { @output.success(timer) }
      assert_match(/Success/i, out)
      refute_match(/prep/i, out)
    end

    def test_success_with_prep
      timer = Shell::Timer.new(prep: 0.2345, main: 1.2345)
      out, _err = capture_subprocess_io { @output.success(timer) }
      assert_match(/Success/i, out)
      assert_match(/prep/i, out)
    end

    def test_failure
      details = 'Result Details'
      out, _err = capture_subprocess_io { @output.failure(details) }
      assert_match(/Failure/i, out)
      assert_match(/#{details}/i, out)
    end

    def test_unrecoverable
      details = 'Unrecoverable Failure 12345'
      out, _err = capture_subprocess_io { @output.unrecoverable(details) }
      assert_match(/Unrecoverable Error/i, out)
      assert_match(/#{details}/i, out)
    end

    def test_unfiltered
      content = 'Content'
      out, _err = capture_subprocess_io { @output.unfiltered(content) }
      assert_match(/#{content}/i, out)
    end

    def test_unfiltered_skips_printing_if_nothing_to_show
      content = nil
      out, _err = capture_subprocess_io { @output.unfiltered(content) }
      assert_empty out

      content = ''
      out, _err = capture_subprocess_io { @output.unfiltered(content) }
      assert_empty out
    end

    def test_guidance
      summary = 'Summary'
      details = 'Details'
      out, _err = capture_subprocess_io { @output.guidance(summary, details) }
      assert_match(/#{summary}/i, out)
      assert_match(/#{details}/i, out)
    end

    def test_skips_guidance_when_details_nil
      out, _err = capture_subprocess_io { @output.guidance('Test', nil) }
      assert out.strip.empty?
    end

    def test_no_failures_to_retry
      out, _err = capture_subprocess_io { @output.no_failures_to_retry }
      assert_match(/No failures to retry/i, out)
    end

    def test_no_previous_run
      out, _err = capture_subprocess_io { @output.no_previous_run }
      assert_match(/No previous run found/i, out)
    end

    def test_run_summary_shows_tool_names
      entries = [
        { name: 'Rubocop', files: [] },
        { name: 'Reek', files: [] }
      ]
      out, _err = capture_subprocess_io { @output.run_summary(entries) }
      assert_match(/Rubocop/, out)
      assert_match(/Reek/, out)
    end

    def test_run_summary_shows_files_under_tool
      entries = [
        { name: 'Rubocop', files: ['lib/reviewer/batch.rb', 'lib/reviewer/command.rb'] }
      ]
      out, _err = capture_subprocess_io { @output.run_summary(entries) }
      assert_match(/Rubocop/, out)
      assert_match(%r{lib/reviewer/batch.rb}, out)
      assert_match(%r{lib/reviewer/command.rb}, out)
    end

    def test_run_summary_omits_files_when_empty
      entries = [
        { name: 'Rubocop', files: [] }
      ]
      out, _err = capture_subprocess_io { @output.run_summary(entries) }
      assert_match(/Rubocop/, out)
      refute_match(%r{lib/}, out)
    end

    def test_run_summary_skips_output_when_empty
      out, _err = capture_subprocess_io { @output.run_summary([]) }
      assert_empty out
    end

    def test_batch_summary_shows_checkmark_and_timing
      out, _err = capture_subprocess_io { @output.batch_summary(3, 1.5) }
      assert_match(/✓/, out)
      assert_match(/~1.5 seconds/, out)
      assert_match(/3 tools/, out)
    end
  end
end
