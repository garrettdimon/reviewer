# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class SessionTest < Minitest::Test
    # Minimal files stub
    EmptyFiles = Struct.new(nil) do
      def to_a = []
      def raw = []
    end

    # Minimal keywords stub — no failed keyword, no provided keywords
    StubKeywords = Struct.new(nil) do
      def failed? = false
      def provided = []
      def for_tool_names = []
      def unrecognized = []
    end

    # Keywords stub with provided keywords
    StubKeywordsWithProvided = Struct.new(:provided) do
      def failed? = false
      def for_tool_names = []
      def unrecognized = []
      def possible = %w[staged unstaged modified untracked failed]
    end

    # Keywords stub with failed keyword
    StubKeywordsFailed = Struct.new(nil) do
      def failed? = true
      def provided = ['failed']
      def for_tool_names = []
      def unrecognized = []
    end

    # Stub arguments with configurable options
    StubArgs = Struct.new(:format, :json?, :raw?, :streaming?, keyword_init: true) do
      def files = EmptyFiles.new
      def keywords = StubKeywords.new
      def tags = []

      def runner_strategy(multiple_tools:)
        return Runner::Strategies::Passthrough if raw?
        return Runner::Strategies::Captured unless streaming?

        multiple_tools ? Runner::Strategies::Captured : Runner::Strategies::Passthrough
      end
    end

    StubArgsWithKeywords = Struct.new(:format, :json?, :raw?, :streaming?, :keyword_values, keyword_init: true) do
      def files = EmptyFiles.new
      def keywords = StubKeywordsWithProvided.new(keyword_values || [])
      def tags = []

      def runner_strategy(multiple_tools:)
        return Runner::Strategies::Passthrough if raw?
        return Runner::Strategies::Captured unless streaming?

        multiple_tools ? Runner::Strategies::Captured : Runner::Strategies::Passthrough
      end
    end

    StubArgsWithFailed = Struct.new(:format, :json?, :raw?, :streaming?, keyword_init: true) do
      def files = EmptyFiles.new
      def keywords = StubKeywordsFailed.new
      def tags = Arguments::Tags.new(provided: [], keywords: [])

      def runner_strategy(multiple_tools:)
        return Runner::Strategies::Passthrough if raw?
        return Runner::Strategies::Captured unless streaming?

        multiple_tools ? Runner::Strategies::Captured : Runner::Strategies::Passthrough
      end
    end

    # Keywords stub with unrecognized keywords
    StubKeywordsUnrecognized = Struct.new(:provided, :unrecognized) do
      def failed? = false
      def for_tool_names = []
      def possible = %w[staged unstaged modified untracked failed list enabled_tool]
    end

    # Stub arguments with unrecognized keywords
    StubArgsWithUnrecognized = Struct.new(:format, :json?, :raw?, :streaming?, :keyword_stub, keyword_init: true) do
      def files = EmptyFiles.new
      def keywords = keyword_stub
      def tags = Arguments::Tags.new(provided: [], keywords: [])

      def runner_strategy(multiple_tools:)
        multiple_tools ? Runner::Strategies::Captured : Runner::Strategies::Passthrough
      end
    end

    def build_session(arguments: nil, tools: nil, output: nil, history: nil)
      Session.new(
        arguments: arguments || StubArgs.new(format: :streaming, json?: false, raw?: false, streaming?: true),
        tools: tools || Reviewer.tools,
        output: output || Output.new,
        history: history || Reviewer.history
      )
    end

    def test_review_runs_tools_and_returns_exit_status
      tools_collection = Tools.new
      tools_collection.stub(:current, [Tool.new(:list)]) do
        session = build_session(tools: tools_collection)
        _out, _err = capture_subprocess_io do
          assert_kind_of Integer, session.review
        end
      end
    end

    def test_review_returns_zero_for_successful_tools
      tools_collection = Tools.new
      tools_collection.stub(:current, [Tool.new(:list)]) do
        session = build_session(tools: tools_collection)
        _out, _err = capture_subprocess_io do
          assert_equal 0, session.review
        end
      end
    end

    def test_format_returns_exit_status
      tools_collection = Tools.new
      tools_collection.stub(:current, [Tool.new(:enabled_tool)]) do
        session = build_session(tools: tools_collection)
        _out, _err = capture_subprocess_io do
          assert_kind_of Integer, session.format
        end
      end
    end

    def test_returns_zero_when_no_matching_tools
      tools_collection = Tools.new
      tools_collection.stub(:current, []) do
        session = build_session(tools: tools_collection)
        _out, _err = capture_subprocess_io do
          assert_equal 0, session.review
        end
      end
    end

    def test_warns_about_no_matching_tools
      tools_collection = Tools.new
      tools_collection.stub(:current, []) do
        session = build_session(tools: tools_collection)
        out, _err = capture_subprocess_io { session.review }
        assert_match(/no matching tools/i, out)
      end
    end

    def test_json_format_outputs_json
      stub_args = StubArgs.new(format: :json, json?: true, raw?: false, streaming?: false)
      tools_collection = Tools.new
      tools_collection.stub(:current, [Tool.new(:list)]) do
        session = build_session(arguments: stub_args, tools: tools_collection)
        out, _err = capture_subprocess_io { session.review }
        assert_match(/"success":\s*true/, out)
        assert_match(/"tools":/, out)
      end
    end

    def test_summary_format_outputs_checkmarks
      stub_args = StubArgs.new(format: :summary, json?: false, raw?: false, streaming?: false)
      tools_collection = Tools.new
      tools_collection.stub(:current, [Tool.new(:list)]) do
        session = build_session(arguments: stub_args, tools: tools_collection)
        out, _err = capture_subprocess_io { session.review }
        assert_match(/✓/, out)
        assert_match(/All passed/i, out)
      end
    end

    def test_missing_tools_shown_in_streaming_mode
      tools_collection = Tools.new
      tools_collection.stub(:current, [Tool.new(:list), Tool.new(:missing_with_install)]) do
        session = build_session(tools: tools_collection)
        out, _err = capture_subprocess_io { session.review }
        assert_match(/not installed:/i, out)
        assert_match(/Missing With Install/i, out)
      end
    end

    def test_failed_with_nothing_to_run_exits_with_message
      stub_args = StubArgsWithFailed.new(format: :streaming, json?: false, raw?: false, streaming?: true)
      tools_collection = Tools.new
      tools_collection.stub(:failed_from_history, []) do
        session = build_session(arguments: stub_args, tools: tools_collection)
        out, _err = capture_subprocess_io { session.review }
        assert_match(/No/, out)
      end
    end

    def test_run_summary_shown_with_keywords_and_multiple_tools
      stub_args = StubArgsWithKeywords.new(
        format: :streaming, json?: false, raw?: false, streaming?: true,
        keyword_values: ['list']
      )
      tools_collection = Tools.new
      tools_collection.stub(:current, [Tool.new(:list), Tool.new(:enabled_tool)]) do
        session = build_session(arguments: stub_args, tools: tools_collection)
        out, _err = capture_subprocess_io { session.review }
        assert_match(/List/, out)
        assert_match(/Enabled Test Tool/, out)
      end
    end

    def test_review_without_clear_screen
      tools_collection = Tools.new
      tools_collection.stub(:current, [Tool.new(:list)]) do
        session = build_session(tools: tools_collection)
        _out, _err = capture_subprocess_io { session.review }
        # Verify review runs without error
      end
    end

    def test_warns_about_unrecognized_keywords
      keyword_stub = StubKeywordsUnrecognized.new(%w[lsit], %w[lsit])
      stub_args = StubArgsWithUnrecognized.new(
        format: :streaming, json?: false, raw?: false, streaming?: true,
        keyword_stub: keyword_stub
      )
      tools_collection = Tools.new
      tools_collection.stub(:current, [Tool.new(:list)]) do
        session = build_session(arguments: stub_args, tools: tools_collection)
        out, _err = capture_subprocess_io { session.review }
        assert_match(/lsit/, out)
      end
    end

    def test_json_returns_zero_when_no_matching_tools
      stub_args = StubArgs.new(format: :json, json?: true, raw?: false, streaming?: false)
      tools_collection = Tools.new
      tools_collection.stub(:current, []) do
        session = build_session(arguments: stub_args, tools: tools_collection)
        _out, _err = capture_subprocess_io do
          assert_equal 0, session.review
        end
      end
    end

    def test_failed_with_previous_run_but_no_failures
      stub_args = StubArgsWithFailed.new(format: :streaming, json?: false, raw?: false, streaming?: true)
      history = Reviewer.history
      tools_collection = Tools.new

      # Record a passing status so history exists
      history.set(:list, :last_status, :passed)

      tools_collection.stub(:failed_from_history, []) do
        session = build_session(arguments: stub_args, tools: tools_collection, history: history)
        out, _err = capture_subprocess_io { session.review }
        assert_match(/no failures/i, out)
      end
    ensure
      history.set(:list, :last_status, nil)
    end

    def test_failed_with_no_previous_run
      stub_args = StubArgsWithFailed.new(format: :streaming, json?: false, raw?: false, streaming?: true)
      history = Reviewer.history
      tools_collection = Tools.new

      # Clear all statuses so no previous run exists
      tools_collection.all.each { |tool| history.set(tool.key, :last_status, nil) }

      tools_collection.stub(:failed_from_history, []) do
        session = build_session(arguments: stub_args, tools: tools_collection, history: history)
        out, _err = capture_subprocess_io { session.review }
        assert_match(/no previous run/i, out)
      end
    end

    def test_streaming_failure_does_not_show_batch_summary
      tools_collection = Tools.new
      tools_collection.stub(:current, [Tool.new(:missing_command)]) do
        session = build_session(tools: tools_collection)
        out, _err = capture_subprocess_io { session.review }
        refute_match(/all passed/i, out)
      end
    end
  end
end
