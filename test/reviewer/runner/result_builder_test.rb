# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class Runner
    class ResultBuilderTest < Minitest::Test
      def test_builds_skipped_result
        result = build(skipped: true)

        assert result.skipped
        assert result.success
        assert_equal 0, result.exit_status
        assert_equal 0, result.duration
        assert_nil result.command_string
      end

      def test_builds_missing_result
        result = build(missing: true)

        assert result.missing
        refute result.success
        assert_equal 127, result.exit_status
        assert_equal 0, result.duration
      end

      def test_builds_executed_result
        result = build

        refute result.skipped
        assert result.success
        assert_equal 0, result.exit_status
        assert_equal 3.5, result.duration
        assert_equal 'stdout', result.stdout
        assert_equal 'stderr', result.stderr
      end

      def test_builds_failed_result
        result = build(success: false, exit_status: 1)

        refute result.success
        assert_equal 1, result.exit_status
      end

      private

      def build(skipped: false, missing: false, success: true, exit_status: nil)
        tool = Tool.new(:enabled_tool)
        command = Command.new(tool, :review)
        shell = Shell.new

        status = exit_status || (missing ? 127 : 0)
        mock_status = MockProcessStatus.new(exitstatus: status)
        mock_result = Shell::Result.new('stdout', 'stderr', mock_status)
        mock_timer = Shell::Timer.new(prep: 1.0, main: 2.5)

        shell.stub(:result, mock_result) do
          shell.stub(:timer, mock_timer) do
            ResultBuilder.new(
              tool: tool,
              command: command,
              shell: shell,
              skipped: skipped,
              missing: missing,
              success: success
            ).build
          end
        end
      end
    end
  end
end
