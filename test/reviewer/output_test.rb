# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class OutputTest < MiniTest::Test
    def setup
      @output = Output.new(printer: Printer.new)
    end

    def test_tool_summary
      tool = Tool.new(:enabled_tool)
      out, _err = capture_subprocess_io { @output.tool_summary(tool) }
      assert_match(/#{tool.name}/i, out)
      assert_match(/#{tool.description}/i, out)
    end

    def test_newline
      out, _err = capture_subprocess_io { @output.newline }
      assert_match(/\n/i, out)
    end

    def test_divider
      out, _err = capture_subprocess_io { @output.divider }
      assert_match(/#{Output::DIVIDER}/i, out)
    end

    def test_current_command
      command_string = 'ls -la'
      out, _err = capture_subprocess_io { @output.current_command(command_string) }
      assert_match(/Running:/i, out)
      assert_match(/#{command_string}/i, out)
    end

    def test_success_without_prep
      timer = Shell::Timer.new(main: 1.2345)
      out, _err = capture_subprocess_io { @output.success(timer) }
      assert_match(/Success/i, out)
      refute_match(/prep/i, out)
    end

    def test_success_with_prep
      timer = Shell::Timer.new(prep: 0.2345, main: 1.2345)
      out, _err = capture_subprocess_io { @output.success(timer) }
      assert_match(/Success/i, out)
      assert_match(/prep/i, out)
    end

    def test_failure
      details = 'Result Details'
      out, _err = capture_subprocess_io { @output.failure(details) }
      assert_match(/Failure/i, out)
      assert_match(/#{details}/i, out)
    end

    def test_unrecoverable
      details = 'Unrecoverable Failure 12345'
      out, _err = capture_subprocess_io { @output.unrecoverable(details) }
      assert_match(/Unrecoverable Error/i, out)
      assert_match(/#{details}/i, out)
    end

    def test_guidance
      summary = 'Summary'
      details = 'Details'
      out, _err = capture_subprocess_io { @output.guidance(summary, details) }
      assert_match(/#{summary}/i, out)
      assert_match(/#{details}/i, out)
    end

    def test_skips_guidance_when_details_nil
      out, _err = capture_subprocess_io { @output.guidance('Test', nil) }
      assert out.strip.empty?
    end

    def test_syntax_guidance_with_ignore_link
      link = 'https://example.com/ignore'
      out, _err = capture_subprocess_io { @output.syntax_guidance(ignore_link: link) }
      assert_includes(out, 'Selectively Ignore a Rule:')
      assert_includes(out, link)
    end

    def test_syntax_guidance_with_disable_link
      link = 'https://example.com/disable'
      out, _err = capture_subprocess_io do
        @output.syntax_guidance(disable_link: link)
      end
      assert_includes(out, 'Fully Disable a Rule:')
      assert_includes(out, link)
    end

    def test_missing_executable_guidance
      command = Command.new(:missing_command, :review, :total_silence)
      out, _err = capture_subprocess_io { @output.missing_executable_guidance(command) }
      assert_match(/Failure/i, out)
      assert_match(/#{command.tool.name}/i, out)
      assert_match(/Missing executable for/i, out)
      assert_match(/Try installing/i, out)
      assert_match(/Read the installation guidance/i, out)
    end

    def test_missing_executable_guidance_without_installation_help
      command = Command.new(:missing_command_without_guidance, :review, :total_silence)
      out, _err = capture_subprocess_io { @output.missing_executable_guidance(command) }
      assert_match(/Failure/i, out)
      assert_match(/#{command.tool.name}/i, out)
      assert_match(/Missing executable for/i, out)
      refute_match(/Try installing/i, out)
      refute_match(/Read the installation guidance/i, out)
    end
  end
end
