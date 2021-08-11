# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class Runner
    module Strategies
      class SilentTest < MiniTest::Test
        def test_quiet_runner_implementation
          quiet_runner = Runner.new(:list, :review, Runner::Strategies::Captured)

          result = nil
          capture_subprocess_io { result = quiet_runner.run }
          assert quiet_runner.success?
          assert_equal 0, result
        end

        def test_quiet_runner_implementation_with_prep
          History.reset!
          quiet_runner = Runner.new(:list, :review, Runner::Strategies::Captured)

          result = nil
          capture_subprocess_io { result = quiet_runner.run }
          assert quiet_runner.success?
          assert_equal 0, result
        end

        def test_quiet_runner_standard_failure_implementation
          quiet_runner = Runner.new(:failing_command, :review, Runner::Strategies::Captured)

          result = nil
          capture_subprocess_io { result = quiet_runner.run }
          refute quiet_runner.success?
          assert quiet_runner.rerunnable?
          assert_equal 1, result
          assert_equal Runner::Strategies::Passthrough, quiet_runner.strategy
        end

        def test_quiet_runner_total_failure_implementation
          quiet_runner = Runner.new(:missing_command, :review, Runner::Strategies::Captured)

          result = nil
          capture_subprocess_io { result = quiet_runner.run }
          refute quiet_runner.success?
          refute quiet_runner.rerunnable?
          assert_equal 127, result
          assert_equal Runner::Strategies::Captured, quiet_runner.strategy
        end
      end
    end
  end
end
