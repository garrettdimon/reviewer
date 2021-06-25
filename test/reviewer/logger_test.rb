# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class LoggerTest < MiniTest::Test
    def setup
      ensure_test_configuration!

      @tool = Tool.new(:enabled_tool)
      @logger = Logger.new
    end

    def test_running_context
      out, _err = capture_subprocess_io do
        @logger.running(@tool)
      end
      assert_match(/#{@tool.name}/i, out)
      assert_match(/#{@tool.description}/i, out)
    end

    def test_command_context
      command_string = 'cmd'
      out, _err = capture_subprocess_io do
        @logger.command(command_string)
      end
      assert_includes(out, Reviewer::Logger::PROMPT)
      assert_match(/#{command_string}/i, out)
    end

    def test_rerunning_context
      out, _err = capture_subprocess_io do
        @logger.rerunning(@tool)
      end
      assert_match(/Re-running #{@tool.name} verbosely/i, out)
    end

    def test_success_context
      elapsed_time = 1.2345
      out, _err = capture_subprocess_io do
        @logger.success(elapsed_time)
      end
      assert_includes(out, Reviewer::Logger::SUCCESS)
      assert_match(/#{elapsed_time.round(3)}s/i, out)
    end

    def test_failure_context
      message = 'Faily McFailface'
      out, _err = capture_subprocess_io do
        @logger.failure(message)
      end
      assert_includes(out, Reviewer::Logger::FAILURE)
      assert_match(/#{message}/i, out)
    end

    def test_guidance_context
      summary = 'Summary'
      details = 'Details'
      out, _err = capture_subprocess_io do
        @logger.guidance(summary, details)
      end
      assert_match(/#{summary}/i, out)
      assert_match(/#{details}/i, out)
    end
  end
end
