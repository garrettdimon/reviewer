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

    def test_running_direct_command_returns_zero_on_success
      result = nil
      capture_subprocess_io { result = @shell.direct('ls') }
      assert_equal 0, result
    end

    def test_running_direct_command_returns_one_on_failure
      result = nil
      capture_subprocess_io { result = @shell.direct('very_unlikely_to_exist_command') }
      assert_equal 1, result
    end
  end
end
