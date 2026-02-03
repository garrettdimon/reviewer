# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class Runner
    module Strategies
      class CapturedTest < Minitest::Test
        def setup
          @strategy = Runner::Strategies::Captured
        end

        def test_captured_runner_implementation
          captured_runner = Runner.new(build_tool(:list), :review, @strategy, context: default_context)

          result = nil
          capture_subprocess_io { result = captured_runner.run }
          assert captured_runner.success?
          assert_equal 0, result
        end

        def test_captured_runner_implementation_with_prep
          Reviewer.history.clear
          captured_runner = Runner.new(build_tool(:list), :review, @strategy, context: default_context)

          result = nil
          capture_subprocess_io { result = captured_runner.run }
          assert captured_runner.success?
          assert_equal 0, result
        end

        # def test_captured_runner_with_usable_stdout_implementation
        #   captured_runner = Runner.new(build_tool(:list), :review, @strategy, context: default_context)

        #   captured_runner.stub(:stdout, 'standard out') do
        #     result = nil
        #     out, err = capture_subprocess_io { result = captured_runner.run }
        #     assert_equal 'standard out', out
        #   end
        # end

        def test_captured_runner_standard_failure_implementation
          captured_runner = Runner.new(build_tool(:failing_command), :review, @strategy, context: default_context)

          result = nil
          capture_subprocess_io { result = captured_runner.run }
          refute captured_runner.success?
          assert captured_runner.rerunnable?
          assert_equal 1, result
          assert_equal Runner::Strategies::Passthrough, captured_runner.strategy
        end

        def test_captured_runner_failure_with_stderr
          captured_runner = Runner.new(build_tool(:failing_with_stderr), :review, @strategy, context: default_context)

          result = nil
          out, _err = capture_subprocess_io { result = captured_runner.run }
          refute captured_runner.success?
          assert_equal 1, result
          assert_match(/Runtime Errors/i, out)
        end

        def test_captured_runner_total_failure_implementation
          captured_runner = Runner.new(build_tool(:missing_command), :review, @strategy, context: default_context)

          result = nil
          capture_subprocess_io { result = captured_runner.run }
          refute captured_runner.success?
          refute captured_runner.rerunnable?
          assert_equal 127, result
          assert_equal @strategy, captured_runner.strategy
        end

        def test_progress_bar_writes_to_output_stream
          stream = StringIO.new
          printer = Output::Printer.new(stream)
          output = Output.new(printer)
          context = default_context(output: output)
          runner = Runner.new(build_tool(:list), :review, @strategy, context: context)

          # Ensure nothing leaks to real $stdout
          old_stdout = $stdout
          leak = StringIO.new
          $stdout = leak
          runner.run
          $stdout = old_stdout

          assert_empty leak.string, 'Progress bar should not write to $stdout'
          refute_empty stream.string
        end

        def test_progress_bar_omits_ansi_when_not_tty
          stream = StringIO.new
          printer = Output::Printer.new(stream)
          output = Output.new(printer)
          context = default_context(output: output)
          runner = Runner.new(build_tool(:list), :review, @strategy, context: context)
          runner.run
          refute_match(/\e\[/, stream.string)
        end
      end
    end
  end
end
