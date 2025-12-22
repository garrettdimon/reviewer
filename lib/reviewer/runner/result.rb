# frozen_string_literal: true

module Reviewer
  class Runner
    # Immutable value object representing the result of running a single tool
    Result = Data.define(
      :tool_key,
      :tool_name,
      :command_type,
      :command_string,
      :success,
      :exit_status,
      :duration,
      :stdout,
      :stderr
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
          stderr: stderr
        }.compact
      end
    end
  end
end
