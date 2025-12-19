# frozen_string_literal: true

require 'test_helper'

module Reviewer
  class Shell
    class ResultTest < Minitest::Test
      def setup
        @process_status = MockProcessStatus.new(exitstatus: 0, pid: 123)
      end

      def test_exposes_exit_status
        @process_status.exitstatus = 123
        result = Result.new('Standard Out', '', @process_status)
        assert_equal @process_status.exitstatus, result.exit_status
      end

      def test_considered_total_failure_when_exit_status_is_too_high
        @process_status.exitstatus = 0
        result = Result.new('Standard Out', '', @process_status)
        assert result.rerunnable?

        @process_status.exitstatus = 1
        result = Result.new('Standard Out', '', @process_status)
        assert result.rerunnable?

        @process_status.exitstatus = 126
        result = Result.new('Standard Out', '', @process_status)
        refute result.rerunnable?
      end

      def test_recognizes_missing_executable_from_stderr
        stderr = ''
        result = Result.new('Standard Out', stderr, @process_status)
        refute result.executable_not_found?

        stderr = nil
        result = Result.new('Standard Out', stderr, @process_status)
        refute result.executable_not_found?

        stderr = Result::STD_ERROR_STRINGS[:executable_not_found]
        result = Result.new('Standard Out', stderr, @process_status)
        assert result.executable_not_found?
      end

      def test_recognizes_common_exit_statuses
        @process_status.exitstatus = Result::EXIT_STATUS_CODES[:cannot_execute]
        result = Result.new('Standard Out', '', @process_status)
        assert result.cannot_execute?
      end

      def test_casting_to_string_uses_stdout_by_default
        stdout = 'Standard Out'
        result = Result.new(stdout, '', @process_status)
        assert_equal stdout, result.to_s
      end

      def test_casting_to_string_uses_stderr_if_present
        stderr = 'Standard Error'
        stdout = 'Standard Out'
        result = Result.new(stdout, stderr, @process_status)
        assert_includes result.to_s, stderr
        assert_includes result.to_s, stdout
      end
    end
  end
end
