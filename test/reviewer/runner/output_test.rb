# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class Runner
    class OutputTest < MiniTest::Test
      def setup
        @tool = Tool.new(:enabled_tool)
        @command = @tool.review_command
        @process_status = MockProcessStatus.new(exitstatus: 0, pid: 123)
        @result = Result.new('Standard Out from Result', '', @process_status)
        @timer = Timer.new(elapsed: 1.2345, prep: 0.2345)
        @logger = Logger.new
        @output = Output.new(@tool, @command, @result, @timer, logger: @logger)
      end

      def test_current_tool_context
        out, _err = capture_subprocess_io do
          @output.current_tool
        end
        assert_match(/#{@tool.name}/i, out)
        assert_match(/#{@tool.description}/i, out)
      end

      def test_benchmark_context
        out, _err = capture_subprocess_io do
          @output.benchmark
        end
        assert_match(/Success/i, out)
        assert_match(/preparation/i, out)
      end

      def test_running_verbosely_context
        out, _err = capture_subprocess_io do
          @output.raw { 'ls -la' }
        end
        assert_match(/Reviewer ran/i, out)
      end

      def test_current_results_context
        out, _err = capture_subprocess_io do
          @output.current_results
        end
        assert_match(/#{@result.stdout}/i, out)
      end

      def test_missing_executable_guidance
        out, _err = capture_subprocess_io do
          @output.missing_executable_guidance
        end
        assert_includes(out, Output::FAILURE)
        assert_match(/Missing executable for/i, out)
      end

      def test_exit_status_context
        out, _err = capture_subprocess_io do
          @output.exit_status
        end
        assert_match(/Exit Status/i, out)
      end
    end
  end
end
