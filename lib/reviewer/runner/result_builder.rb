# frozen_string_literal: true

module Reviewer
  class Runner
    # Builds an immutable Result from runner execution state.
    # Translates the mutable Runner into a frozen Result value object
    # appropriate for the tool's outcome (skipped, missing, or executed).
    class ResultBuilder
      # Creates a builder from the runner's execution state
      # @param tool [Tool] the tool that was run
      # @param command [Command] the command that was executed
      # @param shell [Shell] the shell with execution results and timing
      # @param skipped [Boolean] whether the tool was skipped (no matching files)
      # @param missing [Boolean] whether the tool's executable was not found
      # @param success [Boolean] whether the tool passed
      #
      # @return [ResultBuilder]
      def initialize(tool:, command:, shell:, skipped:, missing:, success:)
        @tool = tool
        @command = command
        @shell = shell
        @skipped = skipped
        @missing = missing
        @success = success
      end

      # Builds the appropriate Result variant based on the runner's outcome
      #
      # @return [Runner::Result] an immutable result for reporting
      def build
        if @skipped
          skipped_result
        elsif @missing
          missing_result
        else
          executed_result
        end
      end

      private

      def skipped_result
        Result.new(
          tool_key: @tool.key,
          tool_name: @tool.name,
          command_type: @command.type,
          command_string: nil,
          success: true,
          exit_status: 0,
          duration: 0,
          stdout: nil,
          stderr: nil,
          skipped: true
        )
      end

      def missing_result
        Result.new(
          tool_key: @tool.key,
          tool_name: @tool.name,
          command_type: @command.type,
          command_string: @command.string,
          success: false,
          exit_status: @shell.result.exit_status,
          duration: 0,
          stdout: nil,
          stderr: nil,
          skipped: nil,
          missing: true
        )
      end

      def executed_result
        Result.new(
          tool_key: @tool.key,
          tool_name: @tool.name,
          command_type: @command.type,
          command_string: @command.string,
          success: @success,
          exit_status: @shell.result.exit_status,
          duration: @shell.timer.total_seconds,
          stdout: @shell.result.stdout,
          stderr: @shell.result.stderr,
          skipped: nil
        )
      end
    end
  end
end
