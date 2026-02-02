# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class Runner
    class FormatterTest < Minitest::Test
      def setup
        @output = Output.new
        @formatter = Runner::Formatter.new(@output)
      end

      def test_tool_summary
        tool = Tool.new(:enabled_tool)
        out, _err = capture_subprocess_io { @formatter.tool_summary(tool) }
        assert_match(/#{tool.name}/i, out)
        assert_match(/#{tool.description}/i, out)
      end

      def test_current_command
        command_string = 'ls -la'
        out, _err = capture_subprocess_io { @formatter.current_command(command_string) }
        assert_match(/#{command_string}/, out)
        refute_match(/Running:/i, out)
      end

      def test_success_without_prep
        timer = Shell::Timer.new(main: 1.2345)
        out, _err = capture_subprocess_io { @formatter.success(timer) }
        assert_match(/Success/i, out)
        refute_match(/prep/i, out)
      end

      def test_success_with_prep
        timer = Shell::Timer.new(prep: 0.2345, main: 1.2345)
        out, _err = capture_subprocess_io { @formatter.success(timer) }
        assert_match(/Success/i, out)
        assert_match(/prep/i, out)
      end

      def test_failure
        details = 'Result Details'
        out, _err = capture_subprocess_io { @formatter.failure(details) }
        assert_match(/Failure/i, out)
        assert_match(/#{details}/i, out)
      end

      def test_unrecoverable
        details = 'Unrecoverable Failure 12345'
        out, _err = capture_subprocess_io { @formatter.unrecoverable(details) }
        assert_match(/Unrecoverable Error/i, out)
        assert_match(/#{details}/i, out)
      end

      def test_guidance
        summary = 'Summary'
        details = 'Details'
        out, _err = capture_subprocess_io { @formatter.guidance(summary, details) }
        assert_match(/#{summary}/i, out)
        assert_match(/#{details}/i, out)
      end

      def test_skips_guidance_when_details_nil
        out, _err = capture_subprocess_io { @formatter.guidance('Test', nil) }
        assert out.strip.empty?
      end
    end
  end
end
