# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class RunnerTest < Minitest::Test
    def test_to_result_returns_result_instance
      with_mock_shell_result do |result|
        assert_instance_of Runner::Result, result
      end
    end

    def test_to_result_includes_tool_info
      with_mock_shell_result do |result|
        assert_equal :enabled_tool, result.tool_key
        assert_equal 'Enabled Test Tool', result.tool_name
      end
    end

    def test_to_result_includes_command_info
      with_mock_shell_result do |result|
        assert_equal :review, result.command_type
        assert result.command_string.include?('ls')
      end
    end

    def test_to_result_includes_execution_details
      with_mock_shell_result do |result|
        assert result.success
        assert_equal 0, result.exit_status
        assert_equal 3.5, result.duration
        assert_equal 'stdout content', result.stdout
        assert_equal 'stderr content', result.stderr
      end
    end

    def test_determines_success_based_on_configured_max_exit_status_for_review
      runner = Runner.new(build_tool(:enabled_tool), :review, context: default_context)
      max_exit_status = 3
      assert_equal max_exit_status, runner.tool.max_exit_status
      runner.stub(:exit_status, max_exit_status) do
        assert runner.success?
      end
      runner.stub(:exit_status, max_exit_status + 1) do
        refute runner.success?
      end
    end

    def test_ignores_max_exit_status_for_non_review_commands
      runner = Runner.new(build_tool(:enabled_tool), :format, context: default_context)
      runner.stub(:exit_status, 0) do
        assert runner.success?
      end
      runner.stub(:exit_status, 1) do
        refute runner.success?
      end
    end

    def test_skips_when_files_requested_but_none_match_pattern
      context = default_context(arguments: Arguments.new(%w[-f lib/foo.js]))
      runner = Runner.new(build_tool(:file_pattern_tool), :review, context: context)

      capture_subprocess_io do
        exit_status = runner.run
        assert_equal 0, exit_status
      end
      result = runner.to_result

      assert result.success
      assert result.skipped
    end

    def test_does_not_skip_when_files_match_pattern
      context = default_context(arguments: Arguments.new(%w[-f lib/foo.rb]))
      runner = Runner.new(build_tool(:file_pattern_tool), :review, context: context)

      refute runner.command.skip?
    end

    def test_missing_returns_false_by_default
      runner = Runner.new(build_tool(:enabled_tool), :review, context: default_context)
      refute runner.missing?
    end

    def test_missing_returns_true_after_executable_not_found
      runner = Runner.new(build_tool(:missing_command), :review, context: default_context)

      capture_subprocess_io { runner.run }

      assert runner.missing?
    end

    def test_to_result_returns_missing_result_for_executable_not_found
      runner = Runner.new(build_tool(:missing_command), :review, context: default_context)

      capture_subprocess_io { runner.run }

      result = runner.to_result
      assert result.missing
      refute result.success
      assert_equal 127, result.exit_status
      assert_equal 0, result.duration
    end

    def test_missing_tool_is_not_successful
      runner = Runner.new(build_tool(:missing_command), :review, context: default_context)

      capture_subprocess_io { runner.run }

      refute runner.success?
    end

    def test_failed_files_extracts_paths_from_output
      runner = Runner.new(build_tool(:enabled_tool), :review, context: default_context)
      mock_shell_result = Shell::Result.new(
        "lib/reviewer/batch.rb:10: warning\nlib/reviewer/command.rb:20: error",
        '',
        MockProcessStatus.new(exitstatus: 1)
      )

      runner.shell.stub(:result, mock_shell_result) do
        files = runner.failed_files
        assert_kind_of Array, files
      end
    end

    def test_failed_files_returns_empty_for_no_output
      runner = Runner.new(build_tool(:enabled_tool), :review, context: default_context)
      mock_shell_result = Shell::Result.new('', '', MockProcessStatus.new(exitstatus: 0))

      runner.shell.stub(:result, mock_shell_result) do
        assert_empty runner.failed_files
      end
    end

    private

    def with_mock_shell_result
      runner = Runner.new(build_tool(:enabled_tool), :review, context: default_context)
      mock_timer = Shell::Timer.new(prep: 1.0, main: 2.5)
      mock_shell_result = Shell::Result.new('stdout content', 'stderr content', MockProcessStatus.new(exitstatus: 0))

      runner.shell.stub(:timer, mock_timer) do
        runner.shell.stub(:result, mock_shell_result) do
          yield runner.to_result
        end
      end
    end
  end
end
