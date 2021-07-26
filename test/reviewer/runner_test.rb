# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class RunnerTest < MiniTest::Test
    def test_run_and_benchmark_timing
      command = 'ls'
      preparation = 'ls -la'
      runner = Runner.new(command: command, preparation: preparation)
      runner.run_and_benchmark
      refute_nil runner.timer
      refute_nil runner.timer.elapsed
      refute_nil runner.timer.prep
    end

    def test_run_and_benchmark_result_capturing
      command = 'ls'
      preparation = 'ls -la'
      runner = Runner.new(command: command, preparation: preparation)
      runner.run_and_benchmark
      refute_nil runner.result
      refute_nil runner.result.stdout
    end

    def test_direct
      one_off_command = 'ls'
      # Runner doesn't need a command because it runs it directly
      runner = Runner.new(command: nil)
      capture_subprocess_io do
        runner.direct(one_off_command)
      end
      refute_nil runner.result
      assert_equal 0, runner.exit_status
    end

    def test_seed_is_shared_across_runs
      runner = Runner.new(command: 'ls')
      original_seed = runner.seed
      runner.run_and_benchmark
      assert_equal original_seed, runner.seed
    end
  end
end
