# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class GuidanceTest < MiniTest::Test
    def setup
      @output = Output.new(printer: Printer.new)
    end

    def test_missing_executable_guidance
      command = Command.new(:missing_command, :review)
      process_status = MockProcessStatus.new(exitstatus: 127, pid: 123)
      result = Reviewer::Shell::Result.new('Output', 'Error', process_status)

      guidance = Guidance.new(command: command, result: result, output: @output)
      out, _err = capture_subprocess_io { guidance.show }
      assert_match(/Failure/i, out)
      assert_match(/#{command.tool.name}/i, out)
      assert_match(/Missing executable for/i, out)
      assert_match(/Try installing/i, out)
      assert_match(/Read the installation guidance/i, out)
    end

    def test_missing_executable_guidance_without_installation_help
      command = Command.new(:missing_command_without_guidance, :review)
      process_status = MockProcessStatus.new(exitstatus: 127, pid: 123)
      result = Reviewer::Shell::Result.new('Output', 'Error', process_status)

      guidance = Guidance.new(command: command, result: result, output: @output)
      out, _err = capture_subprocess_io { guidance.show }
      assert_match(/Failure/i, out)
      assert_match(/#{command.tool.name}/i, out)
      assert_match(/Missing executable for/i, out)
      refute_match(/Try installing/i, out)
      refute_match(/Read the installation guidance/i, out)
    end

    def test_unrecoverable_guidance
      command = Command.new(:missing_command, :review)
      process_status = MockProcessStatus.new(exitstatus: 126, pid: 123)
      result = Reviewer::Shell::Result.new('Output', 'Error', process_status)

      guidance = Guidance.new(command: command, result: result, output: @output)
      out, _err = capture_subprocess_io { guidance.show }
      assert_match(/Unrecoverable/i, out)
    end

    def test_syntax_guidance
      command = Command.new(:enabled_tool, :review)
      process_status = MockProcessStatus.new(exitstatus: 1, pid: 123)
      result = Reviewer::Shell::Result.new('Output', 'Error', process_status)

      guidance = Guidance.new(command: command, result: result, output: @output)
      out, _err = capture_subprocess_io { guidance.show }
      assert_match(/Ignore/i, out)
    end

    def test_syntax_guidance_with_ignore_link
      command = Command.new(:enabled_tool, :review)
      process_status = MockProcessStatus.new(exitstatus: 1, pid: 123)
      result = Reviewer::Shell::Result.new('Output', 'Error', process_status)

      guidance = Guidance.new(command: command, result: result, output: @output)
      out, _err = capture_subprocess_io { guidance.show }
      assert_match(/Selectively Ignore/i, out)
      assert_includes(out, 'https://example.com/ignore')
    end

    def test_syntax_guidance_with_disable_link
      command = Command.new(:enabled_tool, :review)
      process_status = MockProcessStatus.new(exitstatus: 1, pid: 123)
      result = Reviewer::Shell::Result.new('Output', 'Error', process_status)

      guidance = Guidance.new(command: command, result: result, output: @output)
      out, _err = capture_subprocess_io { guidance.show }
      assert_match(/Fully Disable/i, out)
      assert_includes(out, 'https://example.com/disable')
    end
  end
end
