# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class SessionTest < Minitest::Test
    def build_session(arguments: nil, tools: nil, output: nil, history: nil)
      ctx = Context.new(
        arguments: arguments || Arguments.new([]),
        output: output || Output.new,
        history: history || Reviewer.history
      )
      Session.new(context: ctx, tools: tools || Reviewer.tools)
    end

    def test_review_runs_tools_and_returns_exit_status
      tools_collection = Tools.new(config_file: Reviewer.configuration.file)
      tools_collection.stub(:current, [build_tool(:list)]) do
        session = build_session(tools: tools_collection)
        _out, _err = capture_subprocess_io do
          assert_kind_of Integer, session.review
        end
      end
    end

    def test_review_returns_zero_for_successful_tools
      tools_collection = Tools.new(config_file: Reviewer.configuration.file)
      tools_collection.stub(:current, [build_tool(:list)]) do
        session = build_session(tools: tools_collection)
        _out, _err = capture_subprocess_io do
          assert_equal 0, session.review
        end
      end
    end

    def test_format_returns_exit_status
      tools_collection = Tools.new(config_file: Reviewer.configuration.file)
      tools_collection.stub(:current, [build_tool(:enabled_tool)]) do
        session = build_session(tools: tools_collection)
        _out, _err = capture_subprocess_io do
          assert_kind_of Integer, session.format
        end
      end
    end

    def test_returns_zero_when_no_matching_tools
      tools_collection = Tools.new(config_file: Reviewer.configuration.file)
      tools_collection.stub(:current, []) do
        session = build_session(tools: tools_collection)
        _out, _err = capture_subprocess_io do
          assert_equal 0, session.review
        end
      end
    end

    def test_warns_about_no_matching_tools
      tools_collection = Tools.new(config_file: Reviewer.configuration.file)
      tools_collection.stub(:current, []) do
        session = build_session(tools: tools_collection)
        out, _err = capture_subprocess_io { session.review }
        assert_match(/no matching tools/i, out)
      end
    end

    def test_json_format_outputs_json
      tools_collection = Tools.new(config_file: Reviewer.configuration.file)
      tools_collection.stub(:current, [build_tool(:list)]) do
        session = build_session(arguments: Arguments.new(%w[--json]), tools: tools_collection)
        out, _err = capture_subprocess_io { session.review }
        assert_match(/"success":\s*true/, out)
        assert_match(/"tools":/, out)
      end
    end

    def test_format_json_flag_outputs_json
      tools_collection = Tools.new(config_file: Reviewer.configuration.file)
      tools_collection.stub(:current, [build_tool(:list)]) do
        session = build_session(arguments: Arguments.new(%w[--format json]), tools: tools_collection)
        out, _err = capture_subprocess_io { session.review }
        assert_match(/"success":\s*true/, out)
        assert_match(/"tools":/, out)
      end
    end

    def test_summary_format_outputs_checkmarks
      tools_collection = Tools.new(config_file: Reviewer.configuration.file)
      tools_collection.stub(:current, [build_tool(:list)]) do
        session = build_session(arguments: Arguments.new(%w[--format summary]), tools: tools_collection)
        out, _err = capture_subprocess_io { session.review }
        assert_match(/✓/, out)
        assert_match(/All passed/i, out)
      end
    end

    def test_missing_tools_shown_in_streaming_mode
      tools_collection = Tools.new(config_file: Reviewer.configuration.file)
      tools_collection.stub(:current, [build_tool(:list), build_tool(:missing_with_install)]) do
        session = build_session(tools: tools_collection)
        out, _err = capture_subprocess_io { session.review }
        assert_match(/not installed:/i, out)
        assert_match(/Missing With Install/i, out)
      end
    end

    def test_failed_with_nothing_to_run_exits_with_message
      tools_collection = Tools.new(config_file: Reviewer.configuration.file)
      tools_collection.stub(:failed_from_history, []) do
        session = build_session(arguments: Arguments.new(%w[failed]), tools: tools_collection)
        out, _err = capture_subprocess_io { session.review }
        assert_match(/No/, out)
      end
    end

    def test_run_summary_shown_with_keywords_and_multiple_tools
      tools_collection = Tools.new(config_file: Reviewer.configuration.file)
      tools_collection.stub(:current, [build_tool(:list), build_tool(:enabled_tool)]) do
        session = build_session(arguments: Arguments.new(%w[list]), tools: tools_collection)
        out, _err = capture_subprocess_io { session.review }
        assert_match(/List/, out)
        assert_match(/Enabled Test Tool/, out)
      end
    end

    def test_review_without_clear_screen
      tools_collection = Tools.new(config_file: Reviewer.configuration.file)
      tools_collection.stub(:current, [build_tool(:list)]) do
        session = build_session(tools: tools_collection)
        _out, _err = capture_subprocess_io { session.review }
        # Verify review runs without error
      end
    end

    def test_warns_about_unrecognized_keywords
      tools_collection = Tools.new(config_file: Reviewer.configuration.file)
      tools_collection.stub(:current, [build_tool(:list)]) do
        session = build_session(arguments: Arguments.new(%w[lsit]), tools: tools_collection)
        out, _err = capture_subprocess_io { session.review }
        assert_match(/lsit/, out)
      end
    end

    def test_json_returns_zero_when_no_matching_tools
      tools_collection = Tools.new(config_file: Reviewer.configuration.file)
      tools_collection.stub(:current, []) do
        session = build_session(arguments: Arguments.new(%w[--json]), tools: tools_collection)
        _out, _err = capture_subprocess_io do
          assert_equal 0, session.review
        end
      end
    end

    def test_failed_with_previous_run_but_no_failures
      history = Reviewer.history
      tools_collection = Tools.new(config_file: Reviewer.configuration.file)

      # Record a passing status so history exists
      history.set(:list, :last_status, :passed)

      tools_collection.stub(:failed_from_history, []) do
        session = build_session(arguments: Arguments.new(%w[failed]), tools: tools_collection, history: history)
        out, _err = capture_subprocess_io { session.review }
        assert_match(/no failures/i, out)
      end
    ensure
      history.set(:list, :last_status, nil)
    end

    def test_failed_with_no_previous_run
      history = Reviewer.history
      tools_collection = Tools.new(config_file: Reviewer.configuration.file)

      # Clear all statuses so no previous run exists
      tools_collection.all.each { |tool| history.set(tool.key, :last_status, nil) }

      tools_collection.stub(:failed_from_history, []) do
        session = build_session(arguments: Arguments.new(%w[failed]), tools: tools_collection, history: history)
        out, _err = capture_subprocess_io { session.review }
        assert_match(/no previous run/i, out)
      end
    end

    def test_does_not_warn_for_valid_tool_name
      tools_collection = Tools.new(config_file: Reviewer.configuration.file)
      tools_collection.stub(:current, [build_tool(:list)]) do
        session = build_session(arguments: Arguments.new(%w[list]), tools: tools_collection)
        out, _err = capture_subprocess_io { session.review }
        refute_match(/Unrecognized/i, out)
      end
    end

    def test_failed_with_tag_keyword_does_not_short_circuit
      tools_collection = Tools.new(config_file: Reviewer.configuration.file)
      tools_collection.stub(:failed_from_history, []) do
        tools_collection.stub(:current, [build_tool(:enabled_tool)]) do
          session = build_session(arguments: Arguments.new(%w[failed ruby]), tools: tools_collection)
          out, _err = capture_subprocess_io { session.review }
          refute_match(/no previous run/i, out)
          refute_match(/no failures/i, out)
        end
      end
    end

    def test_file_keyword_with_no_files_exits_with_message
      tools_collection = Tools.new(config_file: Reviewer.configuration.file)
      tools_collection.stub(:current, [build_tool(:list)]) do
        args = Arguments.new(%w[staged])
        args.stub(:files, Arguments::Files.new(keywords: ['staged'])) do
          session = build_session(arguments: args, tools: tools_collection)
          out, _err = capture_subprocess_io { session.review }
          assert_match(/no.*staged.*files/i, out)
        end
      end
    end

    def test_file_keyword_with_no_files_does_not_run_tools
      tools_collection = Tools.new(config_file: Reviewer.configuration.file)
      tools_collection.stub(:current, [build_tool(:list)]) do
        args = Arguments.new(%w[staged])
        args.stub(:files, Arguments::Files.new(keywords: ['staged'])) do
          session = build_session(arguments: args, tools: tools_collection)
          _out, _err = capture_subprocess_io do
            assert_equal 0, session.review
          end
        end
      end
    end

    def test_json_file_keyword_with_no_files_outputs_json
      tools_collection = Tools.new(config_file: Reviewer.configuration.file)
      tools_collection.stub(:current, [build_tool(:list)]) do
        args = Arguments.new(%w[staged --json])
        args.stub(:files, Arguments::Files.new(keywords: ['staged'])) do
          session = build_session(arguments: args, tools: tools_collection)
          assert_json_early_exit(session, message_pattern: /staged/)
        end
      end
    end

    def test_json_failed_with_nothing_to_run_outputs_json
      tools_collection = Tools.new(config_file: Reviewer.configuration.file)
      tools_collection.stub(:failed_from_history, []) do
        args = Arguments.new(%w[failed --json])
        session = build_session(arguments: args, tools: tools_collection)
        assert_json_early_exit(session, message_pattern: /no/i)
      end
    end

    def assert_json_early_exit(session, message_pattern:)
      out, _err = capture_subprocess_io { session.review }
      parsed = JSON.parse(out)
      assert parsed['success']
      assert_match(message_pattern, parsed['message'])
      assert_equal 0, parsed['summary']['total']
    end

    def test_streaming_failure_does_not_show_batch_summary
      tools_collection = Tools.new(config_file: Reviewer.configuration.file)
      tools_collection.stub(:current, [build_tool(:missing_command)]) do
        session = build_session(tools: tools_collection)
        out, _err = capture_subprocess_io { session.review }
        refute_match(/all passed/i, out)
      end
    end
  end
end
