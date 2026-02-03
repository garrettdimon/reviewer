# frozen_string_literal: true

require_relative '../output/formatting'

module Reviewer
  class Runner
    # Display logic for tool execution: tool identity, success, failure, skipped, guidance
    class Formatter
      include Output::Formatting

      attr_reader :output, :printer
      private :output, :printer

      # Creates a formatter for runner-specific display
      # @param output [Output] the console output handler
      #
      # @return [Formatter]
      def initialize(output)
        @output = output
        @printer = output.printer
      end

      # Prints the tool name and description as a header before execution
      # @param tool [Tool] the tool being run
      #
      # @return [void]
      def tool_summary(tool)
        printer.print(:bold, tool.name)
        printer.puts(:muted, " #{tool.description}")
      end

      # Displays the exact command string being executed for debugging and copy/paste
      # @param command [Command, String] the command to display
      #
      # @return [void]
      def current_command(command)
        printer.print(:default, ' ↳ ')
        printer.puts(:muted, String(command))
        output.newline
      end

      # Displays a success message with timing breakdown
      # @param timer [Shell::Timer] the timer with prep and main execution times
      #
      # @return [void]
      def success(timer)
        printer.print(:success, 'Success')
        printer.print(:success_light, " #{timer.total_seconds}s")
        printer.print(:warning_light, " (#{timer.prep_percent}% prep ~#{timer.prep_seconds}s)") if timer.prepped?
        output.newline
        output.newline
      end

      # Displays a skip notice with the reason
      # @param reason [String] why the tool was skipped
      #
      # @return [void]
      def skipped(reason = 'no matching files')
        printer.print(:muted, 'Skipped')
        printer.puts(:muted, " (#{reason})")
        output.newline
      end

      # Displays a failure message with details and optionally the failed command
      # @param details [String] the failure summary (e.g. exit status)
      # @param command [Command, String, nil] the command that failed, if applicable
      #
      # @return [void]
      def failure(details, command: nil)
        printer.print(:failure, 'Failure')
        printer.puts(:muted, " #{details}")

        return unless command

        output.newline
        printer.puts(:bold, 'Failed Command:')
        printer.puts(:muted, String(command))
      end

      # Displays an unrecoverable error that prevents further execution
      # @param details [String] the error description
      #
      # @return [void]
      def unrecoverable(details)
        printer.puts(:error, 'Unrecoverable Error:')
        printer.puts(:muted, details)
      end

      # Displays contextual guidance after a failure to help the user recover
      # @param summary [String] the guidance heading
      # @param details [String, nil] the guidance body (skipped if nil)
      #
      # @return [void]
      def guidance(summary, details)
        return unless details

        output.newline
        printer.puts(:bold, summary)
        printer.puts(:muted, details)
      end
    end
  end
end
