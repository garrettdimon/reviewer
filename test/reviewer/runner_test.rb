# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class RunnerTest < MiniTest::Test
    def test_quiet_runner_implementation
      quiet_runner = Runner.new(:list, :review, Runner::Strategies::Quiet)

      result = nil
      capture_subprocess_io { result = quiet_runner.run }
      assert quiet_runner.success?
      assert_equal 0, result
    end

    def test_quiet_runner_implementation_with_prep
      History.reset!
      quiet_runner = Runner.new(:list, :review, Runner::Strategies::Quiet)

      result = nil
      capture_subprocess_io { result = quiet_runner.run }
      assert quiet_runner.success?
      assert_equal 0, result
    end

    def test_quiet_runner_standard_failure_implementation
      quiet_runner = Runner.new(:failing_command, :review, Runner::Strategies::Quiet)

      result = nil
      capture_subprocess_io { result = quiet_runner.run }
      refute quiet_runner.success?
      refute quiet_runner.result.total_failure?
      assert_equal 1, result
      assert_equal Runner::Strategies::Verbose, quiet_runner.strategy
    end

    def test_quiet_runner_total_failure_implementation
      quiet_runner = Runner.new(:missing_command, :review, Runner::Strategies::Quiet)

      result = nil
      capture_subprocess_io { result = quiet_runner.run }
      refute quiet_runner.success?
      assert quiet_runner.result.total_failure?
      assert_equal 127, result
      assert_equal Runner::Strategies::Quiet, quiet_runner.strategy
    end

    def test_verbose_runner_implementation
      verbose_runner = Runner.new(:list, :review, Runner::Strategies::Verbose)
      result = nil
      capture_subprocess_io { result = verbose_runner.run }
      assert verbose_runner.success?
    end

    def test_verbose_runner_implementation_with_prep
      History.reset!
      verbose_runner = Runner.new(:list, :review, Runner::Strategies::Verbose)
      result = nil
      capture_subprocess_io { result = verbose_runner.run }
      assert verbose_runner.success?
    end

    def test_determines_success_based_on_configured_max_exit_status_for_review
      runner = Runner.new(:enabled_tool, :review)
      max_exit_status = 3
      assert_equal max_exit_status, runner.tool.max_exit_status
      runner.stub(:exit_status, max_exit_status) do
        assert runner.success?
      end
      runner.stub(:exit_status, max_exit_status + 1) do
        refute runner.success?
      end
    end

    def test_ignores_max_exit_status_for_non_review_commands
      runner = Runner.new(:enabled_tool, :format)
      runner.stub(:exit_status, 0) do
        assert runner.success?
      end
      runner.stub(:exit_status, 1) do
        refute runner.success?
      end
    end
  end
end
