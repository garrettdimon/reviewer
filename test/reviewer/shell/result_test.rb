# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class Shell
    class ResultTest < MiniTest::Test
      def setup
        @process_status = MockProcessStatus.new(exitstatus: 0, pid: 123)
      end

      def test_exposes_exit_status
        @process_status.exitstatus = 123
        result = Result.new('Standard Out', '', @process_status)
        assert_equal @process_status.exitstatus, result.exit_status
      end

      def test_considered_successful_with_zero_exit_code
        result = Result.new('Standard Out', '', @process_status)
        assert_equal 0, result.exit_status
        assert result.success?
      end

      def test_considered_successful_with_custom_exit_code
        @process_status.exitstatus = 3
        result = Result.new('Standard Out', '', @process_status)
        refute result.success?
        assert result.success?(max_exit_status: 3)
      end

      def test_considered_total_failure_when_exit_status_is_too_high
        @process_status.exitstatus = 0
        result = Result.new('Standard Out', '', @process_status)
        refute result.total_failure?

        @process_status.exitstatus = 1
        result = Result.new('Standard Out', '', @process_status)
        refute result.total_failure?

        @process_status.exitstatus = 126
        result = Result.new('Standard Out', '', @process_status)
        assert result.total_failure?
      end

      def test_recognizes_missing_executable_from_stderr
        stderr = ''
        result = Result.new('Standard Out', stderr, @process_status)
        refute result.executable_not_found?

        stderr = Result::STD_ERROR_STRINGS[:executable_not_found]
        result = Result.new('Standard Out', stderr, @process_status)
        assert result.executable_not_found?
      end

      def test_recognizes_common_exit_statuses
        @process_status.exitstatus = Result::EXIT_STATUS_CODES[:cannot_execute]
        result = Result.new('Standard Out', '', @process_status)
        refute result.success?
        assert result.cannot_execute?

        @process_status.exitstatus = Result::EXIT_STATUS_CODES[:terminated]
        result = Result.new('Standard Out', '', @process_status)
        refute result.success?
        assert result.terminated?
      end

      def test_casting_to_string_uses_stdout_by_default
        stdout = 'Standard Out'
        result = Result.new(stdout, '', @process_status)
        assert_equal stdout, result.to_s
      end

      def test_casting_to_string_uses_stderr_if_present
        stdout = 'Standard Out'
        stderr = 'Standard Error'
        result = Result.new(stdout, stderr, @process_status)
        assert_equal stderr, result.to_s
      end
    end
  end
end
