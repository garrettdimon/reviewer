# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class GuidanceTest < MiniTest::Test
    def setup
      # Only load it once per SettingsTest run rather than every test
      @@config ||= ensure_test_configuration! # rubocop:disable Style/ClassVars

      @output = Output.new(printer: Printer.new)
    end

    def test_missing_executable_guidance
      command = Command.new(:missing_command, :review, :total_silence)
      process_status = MockProcessStatus.new(exitstatus: 127, pid: 123)
      result = Reviewer::Shell::Result.new('Output', 'Error', process_status)

      guidance = Guidance.new(command: command, result: result, output: @output)
      out, _err = capture_subprocess_io { guidance.show }
      assert_match(/Missing executable/i, out)
    end

    def test_unrecoverable_guidance
      command = Command.new(:missing_command, :review, :total_silence)
      process_status = MockProcessStatus.new(exitstatus: 126, pid: 123)
      result = Reviewer::Shell::Result.new('Output', 'Error', process_status)

      guidance = Guidance.new(command: command, result: result, output: @output)
      out, _err = capture_subprocess_io { guidance.show }
      assert_match(/Unrecoverable/i, out)
    end

    def test_syntax_guidance
      command = Command.new(:enabled_tool, :review, :total_silence)
      process_status = MockProcessStatus.new(exitstatus: 1, pid: 123)
      result = Reviewer::Shell::Result.new('Output', 'Error', process_status)

      guidance = Guidance.new(command: command, result: result, output: @output)
      out, _err = capture_subprocess_io { guidance.show }
      assert_match(/Ignore/i, out)
    end
  end
end
