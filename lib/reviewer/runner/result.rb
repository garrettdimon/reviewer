# frozen_string_literal: true

module Reviewer
  # Handles running, benchmarking, and printing output for a single command
  class Runner
    # Provides a structure interface for the results of running a command
    class Result
      EXIT_STATUS_CODES = {
        success: 0,
        cannot_execute: 126,
        executable_not_found: 127,
        terminated: 130
      }.freeze

      STD_ERROR_STRINGS = {
        executable_not_found: "can't find executable"
      }.freeze

      attr_reader :stdout, :stderr, :status

      def initialize(stdout, stderr, status)
        @stdout = stdout
        @stderr = stderr
        @status = status
      end

      def exit_status
        status.exitstatus
      end

      def rerunnable?
        exit_status < EXIT_STATUS_CODES[:cannot_execute]
      end

      def success?(max_exit_status: EXIT_STATUS_CODES[:success])
        exit_status <= max_exit_status
      end

      def minor_issue?
        exit_status == EXIT_STATUS_CODES[:minor_issue]
      end

      def major_issue?
        exit_status == EXIT_STATUS_CODES[:major_issue]
      end

      def cannot_execute?
        exit_status == EXIT_STATUS_CODES[:cannot_execute]
      end

      def executable_not_found?
        sym = :executable_not_found

        exit_status == EXIT_STATUS_CODES[sym] || stderr.include?(STD_ERROR_STRINGS[sym])
      end

      def terminated?
        exit_status == EXIT_STATUS_CODES[:terminated]
      end

      def to_s
        stderr.blank? ? stdout : stderr
      end
    end
  end
end
