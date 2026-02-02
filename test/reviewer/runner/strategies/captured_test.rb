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
          captured_runner = Runner.new(:list, :review, @strategy)

          result = nil
          capture_subprocess_io { result = captured_runner.run }
          assert captured_runner.success?
          assert_equal 0, result
        end

        def test_captured_runner_implementation_with_prep
          History.clear
          captured_runner = Runner.new(:list, :review, @strategy)

          result = nil
          capture_subprocess_io { result = captured_runner.run }
          assert captured_runner.success?
          assert_equal 0, result
        end

        # def test_captured_runner_with_usable_stdout_implementation
        #   captured_runner = Runner.new(:list, :review, @strategy)

        #   captured_runner.stub(:stdout, 'standard out') do
        #     result = nil
        #     out, err = capture_subprocess_io { result = captured_runner.run }
        #     assert_equal 'standard out', out
        #   end
        # end

        def test_captured_runner_standard_failure_implementation
          captured_runner = Runner.new(:failing_command, :review, @strategy)

          result = nil
          capture_subprocess_io { result = captured_runner.run }
          refute captured_runner.success?
          assert captured_runner.rerunnable?
          assert_equal 1, result
          assert_equal Runner::Strategies::Passthrough, captured_runner.strategy
        end

        def test_captured_runner_total_failure_implementation
          captured_runner = Runner.new(:missing_command, :review, @strategy)

          result = nil
          capture_subprocess_io { result = captured_runner.run }
          refute captured_runner.success?
          refute captured_runner.rerunnable?
          assert_equal 127, result
          assert_equal @strategy, captured_runner.strategy
        end
      end
    end
  end
end
