# frozen_string_literal: true

module Reviewer
  class Runner
    # Immutable value object representing the result of running a single tool
    #
    # @!attribute [r] tool_key
    #   @return [Symbol] the unique identifier for the tool
    # @!attribute [r] tool_name
    #   @return [String] the human-readable name of the tool
    # @!attribute [r] command_type
    #   @return [Symbol] the type of command run (:review, :format, etc.)
    # @!attribute [r] command_string
    #   @return [String] the full command string that was executed
    # @!attribute [r] success
    #   @return [Boolean] whether the command completed successfully
    # @!attribute [r] exit_status
    #   @return [Integer] the exit status code from the command
    # @!attribute [r] duration
    #   @return [Float] the execution time in seconds
    # @!attribute [r] stdout
    #   @return [String, nil] the standard output from the command
    # @!attribute [r] stderr
    #   @return [String, nil] the standard error from the command
    # @!attribute [r] skipped
    #   @return [Boolean] whether the tool was skipped
    Result = Data.define(
      :tool_key,
      :tool_name,
      :command_type,
      :command_string,
      :success,
      :exit_status,
      :duration,
      :stdout,
      :stderr,
      :skipped
    ) do
      # Converts the result to a hash suitable for serialization
      #
      # @return [Hash] hash representation with nil values removed
      def to_h
        {
          tool: tool_key,
          name: tool_name,
          command_type: command_type,
          command: command_string,
          success: success,
          exit_status: exit_status,
          duration: duration,
          stdout: stdout,
          stderr: stderr,
          skipped: skipped
        }.compact
      end
    end
  end
end
