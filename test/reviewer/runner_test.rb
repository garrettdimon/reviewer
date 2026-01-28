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
      runner = Runner.new(:enabled_tool, :review)
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
      runner = Runner.new(:enabled_tool, :format)
      runner.stub(:exit_status, 0) do
        assert runner.success?
      end
      runner.stub(:exit_status, 1) do
        refute runner.success?
      end
    end

    def test_skips_when_files_requested_but_none_match_pattern
      # Set up arguments with only JS files
      Reviewer.instance_variable_set(:@arguments, Arguments.new(%w[-f lib/foo.js]))

      # Tool with *.rb pattern should skip
      runner = Runner.new(:file_pattern_tool, :review)
      capture_subprocess_io do
        exit_status = runner.run
        assert_equal 0, exit_status
      end
      result = runner.to_result

      assert result.success
      assert result.skipped
    ensure
      ensure_test_configuration!
    end

    def test_does_not_skip_when_files_match_pattern
      # Set up arguments with Ruby files
      Reviewer.instance_variable_set(:@arguments, Arguments.new(%w[-f lib/foo.rb]))

      # Tool with *.rb pattern should not skip
      runner = Runner.new(:file_pattern_tool, :review)

      refute runner.command.skip?
    ensure
      ensure_test_configuration!
    end

    private

    def with_mock_shell_result
      runner = Runner.new(:enabled_tool, :review)
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
