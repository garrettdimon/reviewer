# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class ShellTest < MiniTest::Test
    def test_run_and_benchmark_timing
      command = 'ls'
      preparation = 'ls -la'
      shell = Shell.new(command: command, preparation: preparation)
      shell.run_and_benchmark
      refute_nil shell.timer
      refute_nil shell.timer.elapsed
      refute_nil shell.timer.prep
    end

    def test_run_and_benchmark_result_capturing
      command = 'ls'
      preparation = 'ls -la'
      shell = Shell.new(command: command, preparation: preparation)
      shell.run_and_benchmark
      refute_nil shell.result
      refute_nil shell.result.stdout
    end

    def test_direct
      one_off_command = 'ls'
      # Shell doesn't need a command because it runs it directly
      shell = Shell.new(command: nil)
      capture_subprocess_io do
        shell.direct(one_off_command)
      end
      refute_nil shell.result
      assert_equal 0, shell.exit_status
    end

    def test_seed_is_shared_across_runs
      skip "Pending move: Seed is migrated to review command"
      shell = Shell.new(command: 'ls')
      original_seed = shell.seed
      shell.run_and_benchmark
      assert_equal original_seed, shell.seed
    end
  end
end
