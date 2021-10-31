# frozen_string_literal: true

module Reviewer
  class Shell
    # Provides a structure interface for the results of running a command
    class Result
      EXIT_STATUS_CODES = {
        success: 0,
        cannot_execute: 126,
        executable_not_found: 127,
        terminated: 130
      }.freeze

      # Not all command line tools use the 127 exit status when an executable cannot be found, so
      # this provides a home for recognizeable strings in those tools' error messages that we can
      # translate to the appropriate exit status for internal consistency
      STD_ERROR_STRINGS = {
        executable_not_found: "can't find executable"
      }.freeze

      attr_accessor :stdout, :stderr, :status, :exit_status

      # An instance of a result from running a local command. Captures the values for `$stdout`,
      #   `$stderr`, and the exit status of the command to provide a reliable way of interpreting
      #   the results for commands that otherwise use these values inconsistently.
      # @param stdout = nil [String] standard out output from a command
      # @param stderr = nil [String] standard error output from a command
      # @param status = nil [ProcessStatus] an instance of ProcessStatus for a command
      #
      # @example Using with `Open3.capture3`
      #   captured_results = Open3.capture3(command)
      #   result = Result.new(*captured_results)
      #
      # @return [self]
      def initialize(stdout = nil, stderr = nil, status = nil)
        @stdout = stdout
        @stderr = stderr
        @status = status
        @exit_status = status&.exitstatus
      end

      def exists?
        [stdout, stderr, exit_status].compact.any?
      end

      # Determines if re-running a command is entirely futile. Primarily to help when a command
      # fails within a batch and needs to be re-run to show the output
      #
      # @return [Boolean] true if the exit status code is greater than or equal to 126
      def rerunnable?
        exit_status < EXIT_STATUS_CODES[:cannot_execute]
      end

      # Determines whether a command simply cannot be executed.
      #
      # @return [Boolean] true if the exit sttaus code equals 126
      def cannot_execute?
        exit_status == EXIT_STATUS_CODES[:cannot_execute]
      end

      # Determines whether the command failed because the executable cannot be found. Since this is
      # an error that can be corrected fairly predictably and easily, it provides the ability to
      # tailor the error guidance to help folks recover
      #
      # @return [Boolean] true if the exit sttaus code is 127 or there's a recognizable equivalent
      #   value in the standard error string
      def executable_not_found?
        exit_status == EXIT_STATUS_CODES[:executable_not_found] ||
          stderr&.include?(STD_ERROR_STRINGS[:executable_not_found])
      end

      # Returns a string representation of the result
      #
      # @return [String] stdout if present, otherwise stderr
      def to_s
        result_string = ''
        result_string += stderr
        result_string += stdout

        result_string.strip
      end
    end
  end
end
