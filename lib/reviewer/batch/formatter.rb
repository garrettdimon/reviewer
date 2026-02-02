# frozen_string_literal: true

require_relative '../output/formatting'

module Reviewer
  class Batch
    # Display logic for batch execution: summary, run preview, missing tools
    class Formatter
      include Output::Formatting

      attr_reader :output, :printer
      private :output, :printer

      # Creates a formatter for batch execution display
      # @param output [Output] the console output handler
      #
      # @return [Formatter]
      def initialize(output)
        @output = output
        @printer = output.printer
      end

      # Displays a one-line success summary with timing and tool count
      # @param tool_count [Integer] the number of tools that ran
      # @param seconds [Float] total elapsed time in seconds
      #
      # @return [void]
      def summary(tool_count, seconds)
        output.newline
        printer.print(:success, CHECKMARK)
        printer.print(:muted, " ~#{seconds.round(1)} seconds")
        printer.print(:muted, " for #{tool_count} tools") if tool_count > 1
        output.newline
      end

      # Displays a preview of which tools will run and their target files
      # @param entries [Array<Hash>] each with :name and :files keys
      #
      # @return [void]
      def run_summary(entries)
        return if entries.empty?

        entries.each { |entry| print_run_entry(entry) }
        output.newline
      end

      # Displays a list of tools whose executables were not found, with install hints
      # @param missing [Array<Runner::Result>] the results for missing tools
      # @param tools [Array<Tool>] the tools that were in the batch
      #
      # @return [void]
      def missing_tools(missing, tools:)
        output.newline
        printer.puts(:warning, "#{missing.size} not installed:")
        tool_lookup = tools.to_h { |tool| [tool.key, tool] }
        missing.each { |result| print_missing_hint(result.tool_name, tool_lookup[result.tool_key]) }
        output.newline
      end

      # Displays a message when `rvw failed` is used but no tools failed in the last run
      #
      # @return [void]
      def no_failures_to_retry
        printer.puts(:muted, 'No failures to retry')
      end

      # Displays a message when `rvw failed` is used but no previous run exists in history
      #
      # @return [void]
      def no_previous_run
        printer.puts(:muted, 'No previous run found')
      end

      private

      def print_missing_hint(name, tool)
        hint = tool&.installable? ? tool.install_command : ''
        printer.puts(:muted, "  #{name.ljust(22)}#{hint}")
      end

      def print_run_entry(entry)
        printer.puts(:muted, entry[:name])
        entry[:files].each { |file| printer.puts(:muted, "  #{file}") }
      end
    end
  end
end
