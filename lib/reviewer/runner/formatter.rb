# frozen_string_literal: true

require_relative '../output/formatting'

module Reviewer
  class Runner
    # Display logic for tool execution: tool identity, success, failure, skipped, guidance
    class Formatter
      include Output::Formatting

      def initialize(output)
        @output = output
        @printer = output.printer
      end

      def tool_summary(tool)
        @printer.print(:bold, tool.name)
        @printer.puts(:muted, " #{tool.description}")
      end

      def current_command(command)
        @printer.print(:default, ' ↳ ')
        @printer.puts(:muted, String(command))
      end

      def success(timer)
        @printer.print(:success, 'Success')
        @printer.print(:success_light, " #{timer.total_seconds}s")
        @printer.print(:warning_light, " (#{timer.prep_percent}% prep ~#{timer.prep_seconds}s)") if timer.prepped?
        @output.newline
        @output.newline
      end

      def skipped(reason = 'no matching files')
        @printer.print(:muted, 'Skipped')
        @printer.puts(:muted, " (#{reason})")
        @output.newline
      end

      def failure(details, command: nil)
        @printer.print(:failure, 'Failure')
        @printer.puts(:muted, " #{details}")

        return if command.nil?

        @output.newline
        @printer.puts(:bold, 'Failed Command:')
        @printer.puts(:muted, String(command))
      end

      def unrecoverable(details)
        @printer.puts(:error, 'Unrecoverable Error:')
        @printer.puts(:muted, details)
      end

      def guidance(summary, details)
        return if details.nil?

        @output.newline
        @printer.puts(:bold, summary)
        @printer.puts(:muted, details)
      end
    end
  end
end
