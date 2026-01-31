# frozen_string_literal: true

require 'test_helper'

module Reviewer
  # Minimal files stub that returns empty array
  EmptyFiles = Struct.new(nil) do
    def to_a = []
  end

  # Minimal keywords stub that reports no failed keyword
  StubKeywords = Struct.new(nil) do
    def failed? = false
    def provided = []
    def for_tool_names = []
    def unrecognized = []
  end

  # Keywords stub that reports keywords were provided
  StubKeywordsWithProvided = Struct.new(:provided) do
    def failed? = false
    def for_tool_names = []
    def unrecognized = []
  end

  # Keywords stub that reports failed keyword
  StubKeywordsFailed = Struct.new(nil) do
    def failed? = true
    def provided = ['failed']
    def for_tool_names = []
    def unrecognized = []
  end

  # Stub for testing different argument configurations
  StubArgs = Struct.new(:format, :json?, :raw?, :streaming?, keyword_init: true) do
    def files = EmptyFiles.new
    def keywords = StubKeywords.new
    def tags = []
  end

  # Stub that reports keywords were provided
  StubArgsWithKeywords = Struct.new(:format, :json?, :raw?, :streaming?, :keyword_values, keyword_init: true) do
    def files = EmptyFiles.new
    def keywords = StubKeywordsWithProvided.new(keyword_values || [])
    def tags = []
  end

  # Stub with failed keyword and real Tags object
  StubArgsWithFailed = Struct.new(:format, :json?, :raw?, :streaming?, keyword_init: true) do
    def files = EmptyFiles.new
    def keywords = StubKeywordsFailed.new
    def tags = Arguments::Tags.new(provided: [], keywords: [])
  end

  class ReviewerTest < Minitest::Test
    # def setup
    #   Reviewer.reset
    #   Reviewer.configure do |config|
    #     config.file = Pathname('test/fixtures/files/test_commands_runnable.yml')
    #   end
    # end

    def test_that_it_has_a_version_number
      refute_nil VERSION
    end

    def test_returns_largest_exit_status_excluding_missing
      tools = [Tool.new(:list), Tool.new(:missing_command)]

      Reviewer.tools.stub(:current, tools) do
        capture_subprocess_io do
          Reviewer.review
        rescue SystemExit => e
          # Missing tools (exit 127) should not affect exit status
          assert_equal 0, e.status
        end
      end
    end

    def test_review_command
      tools = [Tool.new(:list)]

      Reviewer.tools.stub(:current, tools) do
        capture_subprocess_io do
          Reviewer.review
        rescue SystemExit => e
          assert_equal 0, e.status
        end
      end
    end

    def test_format_command
      tools = [Tool.new(:enabled_tool)]

      Reviewer.tools.stub(:current, tools) do
        capture_subprocess_io do
          Reviewer.format
        rescue SystemExit => e
          assert_equal 0, e.status
        end
      end
    end

    def test_clear_screen
      tools = [Tool.new(:list)]

      Reviewer.tools.stub(:current, tools) do
        capture_subprocess_io do
          Reviewer.review(clear_screen: true)
        rescue SystemExit => e
          assert_equal 0, e.status
        end
      end
    end

    def test_summary_format_outputs_checkmarks
      tools = [Tool.new(:list)]

      Reviewer.reset!
      ensure_test_configuration!

      stub_args = StubArgs.new(format: :summary, json?: false, raw?: false, streaming?: false)

      Reviewer.stub(:arguments, stub_args) do
        Reviewer.tools.stub(:current, tools) do
          out, _err = capture_subprocess_io do
            Reviewer.review
          rescue SystemExit
            # Expected
          end

          assert_match(/✓/, out)
          assert_match(/All passed/i, out)
        end
      end
    end

    def test_json_format_outputs_json
      tools = [Tool.new(:list)]

      Reviewer.reset!
      ensure_test_configuration!

      stub_args = StubArgs.new(format: :json, json?: true, raw?: false, streaming?: false)

      Reviewer.stub(:arguments, stub_args) do
        Reviewer.tools.stub(:current, tools) do
          out, _err = capture_subprocess_io do
            Reviewer.review
          rescue SystemExit
            # Expected
          end

          assert_match(/"success":\s*true/, out)
          assert_match(/"tools":/, out)
        end
      end
    end

    def test_run_summary_shown_with_keywords_and_multiple_tools
      tools = [Tool.new(:list), Tool.new(:enabled_tool)]

      Reviewer.reset!
      ensure_test_configuration!

      stub_args = StubArgsWithKeywords.new(
        format: :streaming, json?: false, raw?: false, streaming?: true,
        keyword_values: ['list']
      )

      Reviewer.stub(:arguments, stub_args) do
        Reviewer.tools.stub(:current, tools) do
          out, _err = capture_subprocess_io do
            Reviewer.review
          rescue SystemExit
            # Expected
          end

          assert_match(/List/, out)
          assert_match(/Enabled Test Tool/, out)
        end
      end
    end

    def test_no_run_summary_without_keywords
      tools = [Tool.new(:list), Tool.new(:enabled_tool)]

      Reviewer.reset!
      ensure_test_configuration!

      stub_args = StubArgs.new(format: :streaming, json?: false, raw?: false, streaming?: true)

      Reviewer.stub(:arguments, stub_args) do
        Reviewer.tools.stub(:current, tools) do
          out, _err = capture_subprocess_io do
            Reviewer.review
          rescue SystemExit
            # Expected
          end

          # run_summary prints bare tool names ("List\n") before execution.
          # Without keywords, the first line should be tool_summary which
          # always includes the description alongside the name.
          first_line = out.lines.first.to_s.strip
          refute_equal 'List', first_line
        end
      end
    end

    def test_no_run_summary_in_json_mode
      tools = [Tool.new(:list), Tool.new(:enabled_tool)]

      Reviewer.reset!
      ensure_test_configuration!

      stub_args = StubArgsWithKeywords.new(
        format: :json, json?: true, raw?: false, streaming?: false,
        keyword_values: ['list']
      )

      Reviewer.stub(:arguments, stub_args) do
        Reviewer.tools.stub(:current, tools) do
          out, _err = capture_subprocess_io do
            Reviewer.review
          rescue SystemExit
            # Expected
          end

          # JSON mode should produce JSON output, not a pre-run summary
          assert_match(/"tools":/, out)
        end
      end
    end

    def test_exits_with_guidance_when_config_missing
      Reviewer.reset!
      Reviewer.configure do |config|
        config.file = Pathname('test/fixtures/files/nonexistent.yml')
      end

      out, _err = capture_subprocess_io do
        Reviewer.review
      rescue SystemExit => e
        assert_equal 0, e.status
      end

      assert_match(/no configuration found/i, out)
      assert_match(/rvw init/, out)
    ensure
      ensure_test_configuration!
    end

    def test_missing_tools_summary_shown_in_streaming_mode
      tools = [Tool.new(:list), Tool.new(:missing_with_install)]

      Reviewer.tools.stub(:current, tools) do
        out, _err = capture_subprocess_io do
          Reviewer.review
        rescue SystemExit
          # Expected
        end

        assert_match(/not installed:/i, out)
        assert_match(/Missing With Install/i, out)
        assert_match(/gem install missing-tool/, out)
      end
    end

    def test_missing_tools_summary_not_shown_in_json_mode
      tools = [Tool.new(:list), Tool.new(:missing_with_install)]

      Reviewer.reset!
      ensure_test_configuration!

      stub_args = StubArgs.new(format: :json, json?: true, raw?: false, streaming?: false)

      Reviewer.stub(:arguments, stub_args) do
        Reviewer.tools.stub(:current, tools) do
          out, _err = capture_subprocess_io do
            Reviewer.review
          rescue SystemExit
            # Expected
          end

          # JSON output should contain missing in the data, not a separate summary
          parsed = JSON.parse(out)
          assert_equal 1, parsed['summary']['missing']
        end
      end
    end

    def test_summary_format_shows_missing_tools
      tools = [Tool.new(:list), Tool.new(:missing_with_install)]

      Reviewer.reset!
      ensure_test_configuration!

      stub_args = StubArgs.new(format: :summary, json?: false, raw?: false, streaming?: false)

      Reviewer.stub(:arguments, stub_args) do
        Reviewer.tools.stub(:current, tools) do
          out, _err = capture_subprocess_io do
            Reviewer.review
          rescue SystemExit
            # Expected
          end

          assert_match(/not installed/i, out)
          assert_match(/Missing With Install/i, out)
        end
      end
    end

    def test_review_dispatches_to_init_when_subcommand
      setup_ran = false
      Setup.stub(:run, -> { setup_ran = true }) do
        ARGV.replace(['init'])
        Reviewer.review
      ensure
        ARGV.replace([])
      end
      assert setup_ran, 'Expected Setup.run to be called for rvw init'
    end

    def test_review_dispatches_to_doctor_when_subcommand
      doctor_ran = false
      Doctor.stub(:run, lambda {
        doctor_ran = true
        Doctor::Report.new
      }) do
        ARGV.replace(['doctor'])
        capture_subprocess_io { Reviewer.review }
      ensure
        ARGV.replace([])
      end
      assert doctor_ran, 'Expected Doctor.run to be called for rvw doctor'
    end

    def test_format_dispatches_to_init_when_subcommand
      setup_ran = false
      Setup.stub(:run, -> { setup_ran = true }) do
        ARGV.replace(['init'])
        Reviewer.format
      ensure
        ARGV.replace([])
      end
      assert setup_ran, 'Expected Setup.run to be called for fmt init'
    end

    def test_format_dispatches_to_doctor_when_subcommand
      doctor_ran = false
      Doctor.stub(:run, lambda {
        doctor_ran = true
        Doctor::Report.new
      }) do
        ARGV.replace(['doctor'])
        capture_subprocess_io { Reviewer.format }
      ensure
        ARGV.replace([])
      end
      assert doctor_ran, 'Expected Doctor.run to be called for fmt doctor'
    end

    def test_failed_with_nothing_to_run_handles_tags_object
      # Exercises the tags.to_a.empty? fix — previously called .empty? on
      # Arguments::Tags which doesn't respond to it
      Reviewer.reset!
      ensure_test_configuration!

      stub_args = StubArgsWithFailed.new(
        format: :streaming, json?: false, raw?: false, streaming?: true
      )

      Reviewer.stub(:arguments, stub_args) do
        Reviewer.tools.stub(:failed_from_history, []) do
          out, _err = capture_subprocess_io do
            Reviewer.review
          rescue SystemExit
            # Expected — exits with 0 when nothing to re-run
          end

          assert_match(/No/, out)
        end
      end
    end
  end
end
