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

    def build_session(arguments: nil, tools: nil, output: nil, history: nil, prompt: nil, configuration: nil)
      Session.new(
        arguments: arguments || StubArgs.new(format: :streaming, json?: false, raw?: false, streaming?: true),
        tools: tools || Reviewer.tools,
        output: output || Output.new,
        history: history || Reviewer.history,
        prompt: prompt || Prompt.new(input: StringIO.new, output: StringIO.new),
        configuration: configuration || Reviewer.configuration
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

    def test_clear_screen_when_requested
      tools_collection = Tools.new
      tools_collection.stub(:current, [Tool.new(:list)]) do
        session = build_session(tools: tools_collection)
        _out, _err = capture_subprocess_io { session.review(clear_screen: true) }
        # No assertion on clear — just verify it doesn't blow up
      end
    end
  end
end
