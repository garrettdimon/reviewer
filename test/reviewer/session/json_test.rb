# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class SessionJSONTest < Minitest::Test
    def build_session(arguments:, tools:)
      context = Context.new(arguments: arguments, output: Output.new, history: Reviewer.history)
      Session.new(context: context, tools: tools)
    end

    def test_json_format_outputs_json
      tools = Tools.new(config_file: Reviewer.configuration.file)
      tools.stub(:current, [build_tool(:list)]) do
        output, = capture_subprocess_io { build_session(arguments: Arguments.new(%w[--json]), tools: tools).review }

        assert_match(/"success":\s*true/, output)
        assert_match(/"tools":/, output)
      end
    end

    def test_format_json_flag_outputs_json
      tools = Tools.new(config_file: Reviewer.configuration.file)
      tools.stub(:current, [build_tool(:list)]) do
        arguments = Arguments.new(%w[--format json])
        output, = capture_subprocess_io { build_session(arguments: arguments, tools: tools).review }

        assert_match(/"success":\s*true/, output)
        assert_match(/"tools":/, output)
      end
    end

    def test_json_returns_zero_when_no_matching_tools
      tools = Tools.new(config_file: Reviewer.configuration.file)
      tools.stub(:current, []) do
        session = build_session(arguments: Arguments.new(%w[--json]), tools: tools)

        _output, _error = capture_subprocess_io { assert_equal 0, session.review }
      end
    end

    def test_json_reports_recognized_selection_with_no_enabled_tools
      arguments = Arguments.new(%w[-t disabled --json])
      tools = Tools.new(arguments: arguments, config_file: Reviewer.configuration.file)

      output, = capture_subprocess_io { assert_equal 0, build_session(arguments: arguments, tools: tools).review }

      assert_equal empty_payload('No matching tools found'), JSON.parse(output)
    end

    def test_json_reports_when_selected_tools_do_not_support_the_command
      arguments = Arguments.new(%w[minimum_viable_tool --json])
      tools = Tools.new(arguments: arguments, config_file: Reviewer.configuration.file)

      output, = capture_subprocess_io { assert_equal 0, build_session(arguments: arguments, tools: tools).format }

      assert_equal empty_payload('No tools support the requested format command'), JSON.parse(output)
    end

    def test_json_file_keyword_with_no_files_outputs_json
      tools = Tools.new(config_file: Reviewer.configuration.file)
      arguments = Arguments.new(%w[staged --json])

      tools.stub(:current, [build_tool(:list)]) do
        with_empty_staged_files(arguments) do
          session = build_session(arguments: arguments, tools: tools)
          assert_json_early_exit(session, message: 'No reviewable staged files found')
        end
      end
    end

    def test_json_failed_with_nothing_to_run_outputs_json
      tools = Tools.new(config_file: Reviewer.configuration.file)
      tools.stub(:failed_from_history, []) do
        arguments = Arguments.new(%w[failed --json])
        session = build_session(arguments: arguments, tools: tools)

        assert_json_early_exit(session, message: 'No failures to retry')
      end
    end

    def test_json_invalid_files_option_uses_the_error_envelope
      arguments = Arguments.new(['--json', '--files='])
      tools = Tools.new(arguments: arguments, config_file: Reviewer.configuration.file)

      output, = capture_subprocess_io do
        assert_equal Session::USAGE_ERROR, build_session(arguments: arguments, tools: tools).review
      end
      assert_equal missing_files_payload, JSON.parse(output)
    end

    private

    def assert_json_early_exit(session, message:)
      output, = capture_subprocess_io { assert_equal 0, session.review }
      assert_equal empty_payload(message), JSON.parse(output)
    end

    def empty_payload(message)
      {
        'schema_version' => 1,
        'state' => 'empty',
        'success' => true,
        'message' => message,
        'summary' => empty_summary,
        'tools' => []
      }
    end

    def empty_summary
      {
        'total' => 0, 'passed' => 0, 'failed' => 0, 'skipped' => 0,
        'missing' => 0, 'not_run' => 0, 'duration' => 0
      }
    end

    def missing_files_payload
      {
        'schema_version' => 1,
        'state' => 'error',
        'error' => {
          'code' => 'missing_files',
          'message' => 'The --files option requires at least one file or path.'
        },
        'summary' => empty_summary,
        'tools' => []
      }
    end

    def with_empty_staged_files(arguments)
      files = Arguments::Files.new(keywords: ['staged'])
      files.stub(:to_a, []) { arguments.stub(:files, files) { yield } }
    end
  end
end
