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

      attr_accessor :stdout, :stderr, :exit_status

      def initialize(stdout = nil, stderr = nil, status = nil)
        @stdout = stdout
        @stderr = stderr
        @exit_status = status&.exitstatus
      end

      def any?
        !stdout.blank? || !stderr.blank?
      end

      def rerunnable?
        exit_status < EXIT_STATUS_CODES[:cannot_execute]
      end

      def success?(max_exit_status: EXIT_STATUS_CODES[:success])
        exit_status <= max_exit_status
      end

      def cannot_execute?
        exit_status == EXIT_STATUS_CODES[:cannot_execute]
      end

      def executable_not_found?
        exit_status == EXIT_STATUS_CODES[:executable_not_found] ||
          stderr&.include?(STD_ERROR_STRINGS[:executable_not_found])
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
