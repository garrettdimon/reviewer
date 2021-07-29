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

    def test_current_command
      command_string = 'ls -la'
      out, _err = capture_subprocess_io { @output.current_command(command_string) }
      assert_match(/Now running/i, out)
      assert_match(/#{command_string}/i, out)
    end

    def test_last_command
      command_string = 'ls -la'
      out, _err = capture_subprocess_io { @output.last_command(command_string) }
      assert_match(/Reviewer ran/i, out)
      assert_match(/#{command_string}/i, out)
    end

    def test_raw_results
      command_string = 'ls -la'
      out, _err = capture_subprocess_io { @output.raw_results(command_string) }
      assert_match(/Now running/i, out)
      assert_match(/CHANGELOG.md/i, out)
      assert_match(/Reviewer ran/i, out)
    end

    def test_syntax_guidance
      content = 'Test Block'
      out, _err = capture_subprocess_io { @output.results_block { 'Test Block' } }
      assert_match(/#{content}/i, out)
    end

    def test_exit_status_context
      exit_status = 123
      out, _err = capture_subprocess_io { @output.exit_status(exit_status) }
      assert_match(/Exit Status/i, out)
      assert_match(/#{exit_status}/i, out)
    end

    def test_success
      timer = Shell::Timer.new(elapsed: 1.2345, prep: 0.2345)
      out, _err = capture_subprocess_io { @output.success(timer) }
      assert_match(/#{Reviewer::Output::SUCCESS}/i, out)
      assert_match(/preparation/i, out)
    end

    def test_failure
      details = 'Result Details'
      out, _err = capture_subprocess_io { @output.failure(details) }
      assert_match(/#{Reviewer::Output::FAILURE}/i, out)
      assert_match(/#{details}/i, out)
    end

    def test_unrecoverable
      details = 'Unrecoverable Failure 12345'
      out, _err = capture_subprocess_io { @output.unrecoverable(details) }
      assert_match(/Uncrecoverable Error Occured/i, out)
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
      assert out.blank?
    end

    def test_missing_executable_guidance
      skip "Pending lower level updates/fixes - May need `allow_printing_output!`"
      tool = Tool.new(:missing_command)
      out, _err = capture_subprocess_io do
        @output.missing_executable_guidance(tool: tool, command: 'tool command')
      end
      assert_includes(out, Output::FAILURE)
      assert_match(/#{tool.name}/i, out)
      assert_match(/Missing executable for/i, out)
      assert_match(/Try installing/i, out)
      assert_match(/Read the installation guidance/i, out)
    end

    def test_missing_executable_guidance_without_installation_help
      skip "Pending lower level updates/fixes - May need `allow_printing_output!`"
      tool = Tool.new(:missing_command_without_guidance)
      out, _err = capture_subprocess_io do
        @output.missing_executable_guidance(tool: tool, command: 'tool command')
      end
      assert_includes(out, Output::FAILURE)
      assert_match(/#{tool.name}/i, out)
      assert_match(/Missing executable for/i, out)
      refute_match(/Try installing/i, out)
      refute_match(/Read the installation guidance/i, out)
    end
  end
end
