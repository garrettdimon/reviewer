# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class ShellTest < Minitest::Test
    def setup
      @shell = Shell.new
    end

    def test_direct
      # Shell doesn't need a command because it runs it directly
      capture_subprocess_io do
        @shell.direct('ls')
      end
      refute_nil @shell.result
      assert_equal 0, @shell.exit_status
    end

    def test_prep_timing
      assert_nil @shell.timer.prep

      @shell.capture_main('ls')
      @shell.capture_prep('ls -la')

      refute_nil @shell.timer
      refute_nil @shell.timer.prep
    end

    def test_main_timing
      assert_nil @shell.timer.main

      @shell.capture_main('ls')
      @shell.capture_prep('ls -la')

      refute_nil @shell.timer
      refute_nil @shell.timer.main
    end

    def test_total_timing
      assert_equal 0, @shell.timer.total

      @shell.capture_main('ls')
      @shell.capture_prep('ls -la')

      refute_nil @shell.timer
      refute_nil @shell.timer.total
    end

    def test_capturing_results
      assert_nil @shell.result.stdout

      @shell.capture_main('ls')
      @shell.capture_prep('ls -la')

      refute_nil @shell.result
      refute_nil @shell.result.stdout
    end

    def test_direct_captures_stdout
      capture_subprocess_io do
        @shell.direct('echo hello')
      end
      assert_includes @shell.result.stdout, 'hello'
    end

    def test_direct_preserves_real_exit_status
      capture_subprocess_io do
        @shell.direct('exit 2')
      end
      assert_equal 2, @shell.exit_status
    end

    def test_running_direct_command_returns_zero_on_success
      capture_subprocess_io { @shell.direct('ls') }
      assert_equal 0, @shell.exit_status
    end

    def test_running_direct_command_returns_127_for_missing_command
      capture_subprocess_io { @shell.direct('very_unlikely_to_exist_command') }
      assert_equal 127, @shell.exit_status
    end

    def test_capture_main_returns_127_for_missing_command
      @shell.capture_main('very_unlikely_to_exist_command')
      assert_equal 127, @shell.exit_status
      assert @shell.result.executable_not_found?
    end
  end
end
