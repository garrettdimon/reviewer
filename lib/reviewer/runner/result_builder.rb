# frozen_string_literal: true

module Reviewer
  class Runner
    # Builds an immutable Result from runner execution state
    class ResultBuilder
      def initialize(tool:, command:, shell:, skipped:, missing:, success:)
        @tool = tool
        @command = command
        @shell = shell
        @skipped = skipped
        @missing = missing
        @success = success
      end

      # @return [Runner::Result]
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
