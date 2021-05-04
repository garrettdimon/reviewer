# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class RunnerTest < MiniTest::Test
    def test_run_exits_cleanly_and_displays_tool_name
      tool = Tool.new(:minimum_viable_tool)
      runner = Runner.new(tool, :review)
      out, _err = capture_subprocess_io do
        exit_status = runner.run
        assert_equal 0, exit_status
      end
      assert_match(/#{tool.name}/i, out)
    end

    def test_failing_command_returns_exit_status_and_retries
      tool = Tool.new(:failing_command)
      runner = Runner.new(tool, :review)
      out, _err = capture_subprocess_io do
        exit_status = runner.run
        assert_equal 1, exit_status
      end
      assert_match(/Exit Status/i, out)
      assert_match(/Re-running/i, out)
    end

    def test_failing_command_returns_exit_status_and_retries
      tool = Tool.new(:missing_command)
      runner = Runner.new(tool, :review)
      out, _err = capture_subprocess_io do
        exit_status = runner.run
        assert_equal Runner::COMMAND_NOT_FOUND_EXIT_STATUS_CODE, exit_status
      end
      assert_match(/Missing executable/i, out)
    end
  end
end
