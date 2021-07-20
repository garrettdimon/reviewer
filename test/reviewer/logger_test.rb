# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class LoggerTest < MiniTest::Test
    def setup
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
      # assert_includes(out, Reviewer::Logger::PROMPT)
      assert_match(/#{command_string}/i, out)
    end

    def test_running_verbosely_context
      out, _err = capture_subprocess_io do
        @logger.last_command('command --flag flag')
      end
      assert_match(/Reviewer ran/i, out)
    end

    def test_success_context
      timer = Runner::Timer.new(elapsed: 1.2345)
      out, _err = capture_subprocess_io do
        @logger.success(timer)
      end
      assert_includes(out, Reviewer::Logger::SUCCESS)
      assert_match(/#{timer.elapsed_seconds}s/i, out)
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
