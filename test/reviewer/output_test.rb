# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class OutputTest < Minitest::Test
    def setup
      @output = Output.new
    end

    # === Primitives ===

    def test_newline
      out, _err = capture_subprocess_io { @output.newline }
      assert_match(/\n/i, out)
    end

    def test_divider
      out, _err = capture_subprocess_io { @output.divider }
      assert_match(/#{Output::DIVIDER}/i, out)
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

    # === Setup display (still delegated) ===

    def test_first_run_greeting_shows_message
      out, _err = capture_subprocess_io { @output.first_run_greeting }
      assert_match(/setting up Reviewer/i, out)
    end

    def test_first_run_greeting_explains_what_init_does
      out, _err = capture_subprocess_io { @output.first_run_greeting }
      assert_match(/auto-detect/i, out)
    end

    def test_first_run_skip_shows_rvw_init
      out, _err = capture_subprocess_io { @output.first_run_skip }
      assert_match(/rvw init/, out)
    end

    def test_setup_already_exists
      file = Pathname('/tmp/project/.reviewer.yml')
      out, _err = capture_subprocess_io { @output.setup_already_exists(file) }
      assert_match(/already exists/i, out)
      assert_match(/rvw init/, out)
    end

    def test_setup_no_tools_detected
      out, _err = capture_subprocess_io { @output.setup_no_tools_detected }
      assert_match(/no supported tools detected/i, out)
      assert_match(%r{github\.com/garrettdimon/reviewer}, out)
    end

    def test_setup_success
      results = [
        Reviewer::Setup::Detector::Result.new(key: :rubocop, reasons: ['rubocop in Gemfile.lock'])
      ]
      out, _err = capture_subprocess_io { @output.setup_success(results) }
      assert_match(/created \.reviewer\.yml/i, out)
      assert_match(/RuboCop/, out)
      assert_match(/Gemfile\.lock/, out)
    end

    # === Session display (still delegated) ===

    def test_unrecognized_keywords_shows_warning
      out, _err = capture_subprocess_io do
        @output.unrecognized_keywords(['rubocp'], { 'rubocp' => 'rubocop' })
      end
      assert_match(/Unrecognized: rubocp/, out)
      assert_match(/did you mean 'rubocop'/, out)
    end

    def test_unrecognized_keywords_without_suggestion
      out, _err = capture_subprocess_io do
        @output.unrecognized_keywords(['zzzzz'], {})
      end
      assert_match(/Unrecognized: zzzzz/, out)
      refute_match(/did you mean/, out)
    end

    def test_no_matching_tools
      out, _err = capture_subprocess_io do
        @output.no_matching_tools(requested: ['rubocp'], available: %w[rubocop tests reek])
      end
      assert_match(/No matching tools found/, out)
      assert_match(/Requested: rubocp/, out)
      assert_match(/Available: rubocop, tests, reek/, out)
    end

    def test_invalid_format
      out, _err = capture_subprocess_io do
        @output.invalid_format('verbose', %i[streaming summary json])
      end
      assert_match(/Unknown format 'verbose'/, out)
      assert_match(/Valid formats:/, out)
    end

    def test_git_error_for_not_a_repo
      out, _err = capture_subprocess_io do
        @output.git_error('fatal: not a git repository')
      end
      assert_match(/Not a git repository/, out)
      assert_match(/Git keywords/, out)
    end

    def test_git_error_for_other_errors
      out, _err = capture_subprocess_io do
        @output.git_error('some other git failure')
      end
      assert_match(/Git command failed/, out)
      assert_match(/Continuing without file filtering/, out)
    end
  end
end
